module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module AppStates
          # Determine the current state of the application in the Nucleus lifecycle.
          # @return [Symbol] application state according to {Nucleus::Enums::ApplicationStates}
          def application_state(app, gear_groups = nil, deployments = nil)
            deployments ||= load_deployments(app[:id])
            gear_groups ||= load_gears(app[:id])

            return :created if state_created?(app, gear_groups, deployments)
            return :deployed if state_deployed?(app, gear_groups, deployments)
            return :running if gear_groups[0][:gears].any? { |gear| gear[:state] == 'started' }
            return :stopped if gear_groups[0][:gears].all? { |gear| gear[:state] == 'stopped' }
            return :idle if gear_groups[0][:gears].all? { |gear| gear[:state] == 'idle' }

            log.debug("Failed to determine state for: #{app}")
            raise Errors::UnknownAdapterCallError,
                  'Could not determine app state. Please verify the Openshift V2 adapter'
          end

          private

          def state_created?(app, gear_groups, deployments)
            # this state exists, but only within the first seconds before the original deployment is applied
            return true if gear_groups[0][:gears].all? { |gear| gear[:state] == 'new' }

            if app[:keep_deployments].to_i > 1
              if deployments.length == 1
                original_os_deployment = original_deployment(app, deployments)
                currently_activated = active_deployment(app, deployments)
                # if the current deployment still is the default, the state must be :created
                return true if original_os_deployment && original_os_deployment[:id] == currently_activated[:id]
              end
              # if there is more than 1 deployment, state can't be :created
            else
              # app was not created with nucleus or has recently been modified :/
              diff = Time.parse(deployments[0][:created_at]).to_i - Time.parse(app[:creation_time]).to_i
              # we can analyse if the deployment was created within 15 seconds after the application,
              # then there can't possibly be an actual code deployment
              return true if diff.abs < 15
            end
            # does not seem to be in state :created
            false
          end

          def state_deployed?(app, gear_groups, deployments)
            # Gears must all be stopped
            return false unless gear_groups[0][:gears].all? { |gear| gear[:state] == 'stopped' }

            deployments ||= load_deployments(app[:id])

            # If there still is the initial deployment, then the state can be deployed.
            original_os_deployment ||= original_deployment(app, deployments)
            return false unless original_os_deployment

            activations = deployments.inject(0) { |a, e| a + e[:activations].length }
            # deduct the activations of the original deployment
            activations -= original_os_deployment[:activations].length
            return false if activations > 1
            true
          end
        end
      end
    end
  end
end
