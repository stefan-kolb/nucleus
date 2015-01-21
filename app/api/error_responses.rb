module Paasal
  module ErrorResponses

    def self.standard_responses
      [[401, 'Unauthorized', Paasal::API::Models::Error],
       [404, 'Resource not found', Paasal::API::Models::Error]]
    end

  end
end
