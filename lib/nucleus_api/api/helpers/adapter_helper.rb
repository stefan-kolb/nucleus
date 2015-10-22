module Nucleus
  module API
    module AdapterHelper
      extend Grape::API::Helpers
      include Nucleus::Logging

      # Get the adapter that is assigned to the current request (via endpoint)
      # @return [Nucleus::Adapters::BaseAdapter] adapter for the currently used endpoint and its vendor
      def adapter
        request_cache.get("#{@env['HTTP_X_REQUEST_ID']}.adapter")
      end
    end
  end
end
