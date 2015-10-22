module Nucleus
  # The {Provider} model will initially be imported from +.yaml+ description files and shall be persisted
  # in the {Nucleus::DB::Store store}. The provider has the following properties:<br>
  # * id (String)
  # * name (String)
  # * vendor (Nucleus::Vendor)
  # * endpoints (Array<Nucleus::Endpoint>)
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Provider < Nucleus::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :endpoints # seq

    def initialize(hash = nil)
      super(hash)
      @endpoints = []
      return if hash.nil?

      return unless hash.key?('endpoints')
      @endpoints = hash['endpoints'].map! { |e| e.is_a?(Nucleus::Endpoint) ? e : Nucleus::Endpoint.new(e) }
    end
  end
end
