module Paasal
  module API
    module Models
      # The Error class has to be thrown each time an error occurs when using the API.
      # Therefore all errors are guaranteed to use the same schema.
      # An error must include the HTTP status code (status), the message (message),
      # developer message (dev_message) and an unique error code (error_code).
      # It may also contain the optional link to detailed information about the error (more_info).
      #
      # A 404 (page / resource not found) error shall then look like this:
      #
      #    {
      #      "status": 404,
      #      "message": "The resource could not be found",
      #      "dev_message": "Please compare your call with the available API resources and actions.",
      #      "error_code": 404
      #    }
      #
      class Error < Grape::Entity
        def self.entity_name
          'Error'
        end

        expose :status, documentation: {
          type: 'int', desc: 'The HTTP status code of the response, always between 100 and 999'
        }

        expose :message, documentation: {
          type: String, desc: 'Basic explanation of the error'
        }

        expose :dev_message, documentation: {
          type: String, desc: 'A detailed message that includes developers notes about how to fix the error'
        }

        expose :error_code, documentation: {
          type: 'int', desc: 'A unique error code for reference and information lookup'
        }

        expose :more_info, safe: true, documentation: {
          type: String, desc: 'Link to more detailed information about the error'
        }
      end
    end
  end
end
