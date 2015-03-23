module Paasal
  module API
    module Models
      class Log < PersistedEntity
        def self.entity_name
          'Log'
        end

        # all properties are read only

        expose :id, documentation: {
          type: String, desc: 'Log ID, unique per application, e.g. \'system\'',
          required_details: { request: false, response: true }
        }

        expose :name, documentation: {
          type: String, desc: 'Name of the logfile, e.g. \'stdout\'',
          required_details: { request: false, response: true }
        }

        expose :type, documentation: {
          type: String, desc: 'Logfile type',
          values: Paasal::API::Application::LogfileType.all,
          required_details: { request: false, response: true }
        }

        expose :_links, using: Paasal::API::Models::BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', is_array: true } do |instance, o|
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