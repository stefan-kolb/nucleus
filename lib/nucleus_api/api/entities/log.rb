module Nucleus
  module API
    module Models
      class Log < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'Log'
        end

        # all properties are read only

        expose :id, documentation: {
          type: String, desc: 'Log ID, unique per application, e.g. \'system\'',
          required: true
        }

        expose :name, documentation: {
          type: String, desc: 'Name of the logfile, e.g. \'stdout\'',
          required: true
        }

        expose :type, documentation: {
          type: String, desc: 'Logfile type',
          values: Nucleus::Enums::ApplicationLogfileType.all,
          required: true
        }

        expose :_links, using: BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', required: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', o[:env]['rack.routing_args'][:application_id],
                                               'logs', instance[:id]]) },
            # link back to the application
            parent: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', o[:env]['rack.routing_args'][:application_id]]) }
          }
        end
      end
    end
  end
end
