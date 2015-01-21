require 'grape/middleware/base'

# TODO report BUG and ask how to fix this issue
module Grape
  module Middleware
    class Formatter < Base

      private

      # store parsed input in env['api.request.body']
      def read_rack_input(body)
        fmt = mime_types[request.media_type] if request.media_type
        fmt ||= options[:default_format]
        if content_type_for(fmt)
          parser = Grape::Parser::Base.parser_for fmt, options
          if parser
            begin
              body = (env['api.request.body'] = parser.call(body, env))
              if body.is_a?(Hash)
                if env['rack.request.form_hash']
                  env['rack.request.form_hash'] = env['rack.request.form_hash'].merge(body)
                else
                  env['rack.request.form_hash'] = body
                end
                env['rack.request.form_input'] = env['rack.input']
              end
            rescue StandardError => e
              # patched to handle parsing errors via the rescue handlers
              if e.message.start_with?('795: unexpected token at')
                raise Paasal::Errors::BadRequestError, e.message.gsub(/795: /, '')
              else
                throw :error, status: 400, message: e.message
              end
            end
          else
            env['api.request.body'] = body
          end
        else
          throw :error, status: 406, message: "The requested content-type '#{request.media_type}' is not supported."
        end
      end
    end
  end
end
