module Grape
  module Middleware
    module Auth
      module DSL
        module ClassMethods
          # Add an authentication type to the API. Currently
          # only `:http_basic`, `:http_digest` are supported.
          def auth(type = nil, options = {}, &block)
            if type
              namespace_inheritable(:auth, options.reverse_merge(type: type.to_sym, proc: block))
              use Grape::Middleware::Auth::DynamicRealmBase, namespace_inheritable(:auth)
            else
              namespace_inheritable(:auth)
            end
          end
        end
      end
    end
  end
end
