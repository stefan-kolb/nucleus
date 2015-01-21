module Paasal
  module DB
    class ProviderDao < Paasal::DB::Store

      def initialize(api_version)
        super(api_version, 'providers')
      end

    end
  end
end
