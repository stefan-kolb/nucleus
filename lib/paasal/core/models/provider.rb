module Paasal
  # The {Provider} model will initially be imported from +.yaml+ description files and shall be persisted
  # in the {Paasal::DB::Store store}. The provider has the following properties:<br>
  # * id (String)
  # * name (String)
  # * vendor (Paasal::Vendor)
  # * endpoints (Array<Paasal::Endpoint>)
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Provider < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :endpoints        # seq

    def initialize(hash = nil)
      super(hash)
      @endpoints = []
      return if hash.nil?

      return unless hash.key?('endpoints')
      @endpoints = hash['endpoints'].map! { |e| e.is_a?(Paasal::Endpoint) ? e : Paasal::Endpoint.new(e) }
    end
  end
end
