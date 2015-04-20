module Paasal
  # The {Vendor} model will initially be imported from +.yaml+ description files and shall be persisted
  # in the {Paasal::DB::Store store}. The vendor has the following properties:<br>
  # * id (String)
  # * name (String)
  # * providers (Array<Paasal::Provider>)
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Vendor < Paasal::AbstractModel
    attr_accessor :name             # text
    attr_accessor :providers        # seq

    def initialize(hash = nil)
      return if hash.nil?
      @name = hash['name']
      @id = hash['id']
      @providers = []

      return unless hash.key?('providers')
      @providers = hash['providers'].map! { |e| e.is_a?(Paasal::Provider) ? e : Paasal::Provider.new(e) }
    end
  end
end
