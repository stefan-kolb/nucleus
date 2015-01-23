module Paasal
  module ErrorResponses
    def self.standard_responses
      [[400, 'Bad Request', Paasal::API::Models::Error],
       [401, 'Unauthorized', Paasal::API::Models::Error],
       [403, 'Forbidden', Paasal::API::Models::Error],
       [404, 'Resource not found', Paasal::API::Models::Error],
       [500, 'Internal processing error', Paasal::API::Models::Error]]
    end
  end
end
