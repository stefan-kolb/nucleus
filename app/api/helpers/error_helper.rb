module Paasal

  # The ErrorHelper class extends {Grape::API::Helpers Grape's Helpers} and provides
  # common methods for the API to raise errors.
  module ErrorHelper
    extend Grape::API::Helpers
    include Paasal::Logging

    # Calling this method ends the user's request and raises an error response.
    # See {Paasal::ErrorHelper#build_error_entity build_error_entity method} for more information about the error response.
    #
    # @param [Hash] error Constant that includes a default message, the status and error code
    # @param [String] dev_message The developer message with a technical explanation why the error has been raised
    def to_error(error, dev_message = nil)
      entity = build_error_entity(error, dev_message)
      log.debug("API error: #{entity[:status]} - #{entity[:message]}")
      error!(entity, entity[:status])
    end

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
    # For more information see the {Paasal::API::Models::Error Error class}.
    #
    # @param [Hash] error Constant that includes a default message, the status and error code
    # @param [String] dev_message The developer message with a technical explanation why the error has been raised
    def build_error_entity(error, dev_message = nil)
      {
        status: error[:status],
        message: error[:message],
        dev_message: dev_message.nil? ? nil : dev_message,
        error_code: error.key?(:error_code) ? error[:error_code] : nil,
        more_info: error.key?(:error_code) ? 'linktodoc' : nil,
        # always use this entity to comply with the error schema
        with: API::Models::Error
      }
    end

  end
end