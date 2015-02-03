module Paasal
  module API
    module Models
      class PersistedEntity < AbstractEntity
        expose :id, safe: true, documentation: {
          desc: 'The ID of the resource',
          type: String,
          required_details: { request: false, response: true }
        }

        expose :created_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the resource was created',
          type: String,
          required_details: { request: false, response: true }
        }

        expose :updated_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the resource was updated the last time',
          type: String,
          required_details: { request: false, response: true }
        }
      end
    end
  end
end
