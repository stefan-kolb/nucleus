module Paasal
  module DB
    class VendorDao < Paasal::DB::Store
      def initialize(api_version)
        super(api_version, 'vendors')
      end
    end
  end
end
