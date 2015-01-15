module Paasal
  module DB
    class EndpointDao < Paasal::DB::Store

      def initialize(api_version)
        super(api_version, 'endpoints')
      end

    end
  end
end