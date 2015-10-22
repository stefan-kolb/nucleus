module Nucleus
  module API
    module LogHelper
      extend Grape::API::Helpers
      include Nucleus::Logging
    end
  end
end
