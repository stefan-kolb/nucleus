module Nucleus
  module API
    module V1
      class ApplicationLogsTail < Grape::API
        helpers SharedParamsHelper
        helpers StreamingHelper
        helpers ErrorHelper

        # TODO: find a way to describe the actual response formats with grape-swagger

        # detect if we are running a test
        if ENV['RACK_ENV'] == 'test'
          # use this middleware only within tests. It simulates the behavior of EM capable servers within rspec tests
          require 'spec/adapter/helpers/mock_stream_server'
          use MockStreamServer
        end
        use ::Rack::Stream

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/logs', desc: 'Application logs',
                 swagger: { nested: false, name: 'application-logs' } do
          params do
            use :log_id
          end
          resource '/:log_id' do
            desc 'Tail a log file and receive updates with the chunked response' do
              failure [[200, 'Returning chunked log file contents']].concat ErrorResponses.standard_responses
            end
            get '/tail' do
              begin
                # THREAD HACK to work with deferred tasks, restore cache key:
                RequestStore.store[:cache_key] = request_cache.get("#{env['HTTP_X_REQUEST_ID']}.auth.cache.key")

                # we need to check file existence before, otherwise we would have returned status 200 already
                unless adapter.log?(params[:application_id], params[:log_id])
                  fail Nucleus::Errors::AdapterResourceNotFoundError, "Invalid log file '#{params[:log_id]}', "\
                    "not available for application '#{params[:application_id]}'"
                end

                tail_polling = nil
                stream = StreamCallback.new(self)
                after_connection_error do
                  # save request id to deferred thread for logging associations
                  Thread.current[:nucleus_request_id] = env['HTTP_X_REQUEST_ID']
                  # tidy resource when the connection was terminated with an error
                  log.debug('Connection error reported by rack-stream')
                  stream.closed = true
                  close
                end

                after_open do
                  # save request id to deferred thread for logging associations
                  Thread.current[:nucleus_request_id] = env['HTTP_X_REQUEST_ID']
                  begin
                    # execute the actual request and stream the logging message
                    tail_polling = adapter.tail(params[:application_id], params[:log_id], stream)

                    # this should at the moment only apply to tests, closing the tailing action when X seconds passed
                    if env['async.callback.auto.timeout']
                      # shorten test duration if we are not recording
                      EM.add_timer(env['async.callback.auto.timeout']) do
                        stream.closed = true
                        close
                      end
                    end
                  rescue StandardError
                    stream.closed = true
                    close
                  end
                end

                before_close do
                  # save request id to deferred thread for logging associations
                  Thread.current[:nucleus_request_id] = env['HTTP_X_REQUEST_ID']
                  log.debug 'Closing API stream, stop tail updates...'
                  tail_polling.stop if tail_polling
                end

                status 200
                header 'Content-Type', 'text/plain'
                # fist chunk, will be included in response but should then be ignored
                ''
              rescue StandardError => e
                # we must manually retrieve our rescue handler, otherwise EM crashes (!)
                error_response = instance_exec(e, &namespace_inheritable(:all_rescue_handler))
                # return the finished rack response as default json response
                status error_response[0]
                header error_response[1]
                error_response[2].body
              end
            end
          end
        end # end of resource
      end
    end
  end
end
