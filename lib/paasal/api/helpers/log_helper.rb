module Paasal
  module API
    module LogHelper
      extend Grape::API::Helpers
      include Paasal::Logging
    end
  end
end
