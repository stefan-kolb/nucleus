module Paasal
  module DB
    class AdapterDao < Paasal::DB::Store
      def initialize(api_version)
        super(api_version, 'adapter_index')
      end
    end
  end
end
