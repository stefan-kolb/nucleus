module Paasal
  class Vendor < Paasal::AbstractModel
    attr_accessor :name             # text
    attr_accessor :providers        # seq

    def initialize(hash = nil)
      return if hash.nil?
      hash = HashWithIndifferentAccess.new hash
      @name = hash[:name]
      @id = hash[:id]
      @providers = []

      return unless hash.key?(:providers)
      @providers = hash[:providers].map! { |e| e.is_a?(Paasal::Provider) ? e : Paasal::Provider.new(e) }
    end

    def representation
      msg = "Vendor: #{@name}"
      msg << ", #{@providers.size} providers" unless @providers.nil? || @providers.empty?
      msg << ', incl. adapter' unless @adapter.nil?
    end
  end
end
