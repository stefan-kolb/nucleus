module Nucleus
  module API
    module Models
      class Application < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'Application'
        end

        expose :id, documentation: {
          type: String, desc: 'Application ID, unique per endpoint, e.g. \'75ab5de0-b323-4607-9d6a-ca6e83ff1312\'',
          required: true
        }

        expose :name, documentation: {
          type: String, desc: 'Application name, e.g. \'murmuring-shelf-1234\'',
          required: true
        }

        # read-only
        expose :active_runtime, documentation: {
          type: String, desc: 'Informal representation of the active runtime for run the application.',
          required: true
        }

        expose :runtimes, documentation: {
          type: String, desc: 'Runtimes, e.g. buildpacks, that shall be used. Any value must either '\
           'be a buildpack URL or the name of a runtime that is already available on the endpoint.',
          required: true,
          is_array: true
        }

        expose :region, documentation: {
          type: String, desc: 'Deployment region',
          required: true
        }

        expose :autoscaled, documentation: {
          type: Virtus::Attribute::Boolean, desc: 'Application auto-scaling: true if enabled, otherwise false',
          required: true
        }

        # read-only
        expose :instances, documentation: {
          type: Integer, desc: 'Number of instances, adjustable via scaling.',
          required: true
        }

        # read-only
        expose :web_url, documentation: {
          type: String, desc: 'URL where the application can always be found, independent of custom domains',
          required: true
        }

        # TODO: add application instance levels for vertical scaling

        # read-only
        expose :state, documentation: {
          type: String, desc: 'The application\'s state',
          values: Nucleus::Enums::ApplicationStates.all,
          required: true
        }

        # read-only
        expose :release_version, documentation: {
          type: String, desc: 'Unique identifier of the active deployment. Can be a UUID or SHA-1 hash',
          required: true
        }

        expose :_links, using: Nucleus::API::Models::ApplicationReferences, documentation: {
          type: 'ApplicationReferences', desc: 'Resource links', required: true
        } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:id]]) },
            # link back to the endpoint
            parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) },
            domains: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                 ['applications', instance[:id], 'domains']) },
            logs: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:id], 'logs']) },
            services: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                  ['applications', instance[:id], 'services']) },
            vars: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:id], 'vars']) }
          }
        end
      end
    end
  end
end
