module Nucleus
  module API
    module ErrorBuilder
      # This method builds an error entity that complies to our defined exception schema:
      #
      #    {
      #      "status": http_status_code
      #      "message": message
      #      "error_code": unique_error_code
      #      "dev_message": detailed_developer_message
      #      "documentation": link_to_error_documentation
      #    }
      #
      # For more information see the {Nucleus::API::Models::Error Error class}.
      #
      # @param [Hash] error Constant that includes a default message, the status and error code
      # @param [String] dev_message The developer message with a technical explanation why the error has been raised
      def build_error_entity(error, dev_message = nil, headers = {})
        {
          status: error[:status],
          message: error[:message],
          dev_message: dev_message.nil? ? nil : dev_message,
          error_code: error.key?(:error_code) ? error[:error_code] : nil,
          more_info: error.key?(:error_code) ? 'linktodoc' : nil,
          # headers to append to the rack response
          headers: headers,
          # always use this entity to comply with the error schema
          with: Nucleus::API::Models::Error
        }
      end
    end
  end
end
