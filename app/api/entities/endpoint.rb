module Paasal
  module API
    module Models
      class Endpoint < AbstractEntity
        def self.entity_name
          'Endpoint'
        end

        # Please do NOT inherit from the persisted entity.
        # For some strange reason the route will then not get exported, resulting in 404 responses

        expose :id, safe: true, documentation: {
          desc: 'The ID of the endpoint',
          type: String,
          required: true,
          presence: false }

        expose :created_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the endpoint was created',
          type: String,
          required: true,
          presence: false }

        expose :updated_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the endpoint was updated the last time',
          type: String,
          required: true,
          presence: false }

        expose :name, documentation: {
          type: String, desc: 'Provider name, e.g. \'IBM Bluemix EU-1\'',
          presence: true,
          allow_blank: false }

        expose :url, documentation: {
          type: String, desc: 'Link to the endpoint\'s root node',
          presence: true, allow_blank: false }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |instance, _o|
          {
            self: { href: link_resource(%w(endpoints), instance) },
              # link back to the provider
              parent: { href: link_resource(%w(providers), instance.provider) },
              # TODO: is only available when authenticated
              # associated applications
              applications: { href: link_child_resource(%w(endpoints), instance, %w(applications)) }, safe: true
          }
        end
      end
    end
  end
end
