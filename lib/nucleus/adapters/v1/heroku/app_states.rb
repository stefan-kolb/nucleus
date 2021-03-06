module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        # AppStates for Heroku, or the logic to determine the current application state
        module AppStates
          private

          def application_state(app, retrieved_dynos = nil)
            # 1: created, both repo and slug are nil
            return Enums::ApplicationStates::CREATED unless repo_or_slug_content?(app)

            # all subsequent states require dynos to be determined
            dynos = retrieved_dynos ? retrieved_dynos : dynos(app[:id])

            # 2: deployed if no dynos assigned
            return Enums::ApplicationStates::DEPLOYED if dynos.empty?

            # 3: stopped if maintenance
            return Enums::ApplicationStates::STOPPED if app[:maintenance] || dynos_not_running?(dynos)

            # 4: running if no maintenance (checked above) and at least ony dyno is up
            return Enums::ApplicationStates::RUNNING if dyno_states(dynos).include?('up')

            # 5: idle if all dynos are idling
            return Enums::ApplicationStates::IDLE if dynos_idle?(dynos)

            # arriving here the above states do not catch all states of the Heroku app, which should not happen ;-)
            log.debug("Faild to determine state for: #{app}, #{dynos}")
            raise Errors::UnknownAdapterCallError, 'Could not determine app state. Please verify the Heroku adapter'
          end

          def repo_or_slug_content?(app)
            return true if !app[:repo_size].nil? && app[:repo_size].to_i > 0
            return true if !app[:slug_size].nil? && app[:slug_size].to_i > 0
            false
          end

          def dyno_states(dynos)
            dynos.collect { |dyno| dyno[:state] }.compact.uniq
          end

          def dynos_idle?(dynos)
            dyno_states = dyno_states(dynos)
            dyno_states.length == 1 && dyno_states[0] == 'idle'
          end

          def dynos_not_running?(dynos)
            dynos.empty? || dyno_states(dynos).reject do |state|
              %w[crashed down starting].include?(state)
            end.empty?
          end
        end
      end
    end
  end
end
