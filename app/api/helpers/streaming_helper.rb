module Paasal
  module StreamingHelper
    extend Grape::API::Helpers
    include ::Rack::Stream::DSL
  end
end
