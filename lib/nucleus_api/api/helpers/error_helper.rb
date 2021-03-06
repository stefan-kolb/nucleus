module Nucleus
  module API
    # The ErrorHelper class extends +Grape::API::Helpers+ (Grape's Helpers) and provides
    # common methods for the API to raise errors.
    module ErrorHelper
      extend Grape::API::Helpers
      include Nucleus::Logging
      include ErrorBuilder

      # Calling this method ends the user's request and raises an error response.
      # See {ErrorBuilder#build_error_entity} for more information
      # about the error response.
      #
      # @param [Hash] error Constant that includes a default message, the status and error code
      # @param [String] dev_message The developer message with technical explanations why the error has been raised
      def to_error(error, dev_message = nil)
        entity = build_error_entity(error, dev_message)
        log.debug("API error: #{entity[:status]} - #{entity[:message]}")
        error!(entity, entity[:status])
      end
    end
  end
end
