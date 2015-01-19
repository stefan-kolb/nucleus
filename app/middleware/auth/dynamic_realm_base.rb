require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      class DynamicRealmBase < Base

        def initialize(app, options = {})
          super(app, options)
        end

        def context
          env['api.endpoint']
        end

        def _call(env)
          self.env = env

          # TODO feature request !?
          # dynamic realm names
          if options.key?(:realm_replace) && !options[:realm_replace].nil?
            # assign values to the realm template and change the realm name
            route_args = env['rack.routing_args']
            replacements = Hash[options[:realm_replace].collect { |s| [s, route_args.key?(s) ? route_args[s] : s] }]
            options[:realm] = options[:realm] % replacements
          end

          if options.key?(:type)
            auth_proc         = options[:proc]
            auth_proc_context = context

            strategy_info   = Grape::Middleware::Auth::Strategies[options[:type]]

            throw(:error, status: 401, message: 'API Authorization Failed.') unless strategy_info.present?

            strategy = strategy_info.create(@app, options) do |*args|
              auth_proc_context.instance_exec(*args, &auth_proc)
            end

            strategy.call(env)

          else
            app.call(env)
          end
        end
      end
    end
  end
end
