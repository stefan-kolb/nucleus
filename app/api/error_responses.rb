module Paasal
  module API
    # The {ErrorResponses} module groups error response that are returned by the RESTful API.
    module ErrorResponses
      # Return all error messages that can be expected to be returned by the RESTful API.
      # @return [Array<Array>] list of rack compatible error messages that the API can be expected to return
      def self.standard_responses
        [[400, 'Bad Request', Paasal::API::Models::Error],
         [401, 'Unauthorized', Paasal::API::Models::Error],
         [403, 'Forbidden', Paasal::API::Models::Error],
         [404, 'Resource not found', Paasal::API::Models::Error],
         [406, 'API vendor or version not found', Paasal::API::Models::Error],
         [422, 'Unprocessable Entity due to invalid parameters', Paasal::API::Models::Error],
         [500, 'Internal processing error', Paasal::API::Models::Error],
         [501, 'Feature not implemented in the adapter', Paasal::API::Models::Error],
         [503, 'Destination service temporarily unavailable', Paasal::API::Models::Error]]
      end
    end
  end
end
