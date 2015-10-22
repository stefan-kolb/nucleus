module Nucleus
  # The {Vendor} model will initially be imported from +.yaml+ description files and shall be persisted
  # in the {Nucleus::DB::Store store}. The vendor has the following properties:<br>
  # * id (String)
  # * name (String)
  # * providers (Array<Nucleus::Provider>)
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Vendor < Nucleus::AbstractModel
    attr_accessor :providers # seq

    def initialize(hash = nil)
      super(hash)
      @providers = []
      return if hash.nil?

      return unless hash.key?('providers')
      @providers = hash['providers'].map! { |e| e.is_a?(Nucleus::Provider) ? e : Nucleus::Provider.new(e) }
    end
  end
end
