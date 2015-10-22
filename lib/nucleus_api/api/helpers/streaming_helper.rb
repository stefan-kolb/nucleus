module Nucleus
  module API
    module StreamingHelper
      extend Grape::API::Helpers
      include ::Rack::Stream::DSL
    end
  end
end
