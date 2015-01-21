module Paasal
  class Vendor < Paasal::AbstractModel
    attr_accessor :name             # text
    attr_accessor :providers        # seq
    attr_accessor :adapter

    def initialize(hash = nil)
      if hash.nil?
        return
      end
      @name = hash['name']
      @id = hash['id']

      v = hash['providers']
      if v
        @providers = v.map! { |e| e.is_a?(Paasal::Provider) ? e : Paasal::Provider.new(e) }
      else
        @providers = v
      end
    end

    def representation
      msg = "Vendor: #{@name}"
      msg << ", #{@providers.size} providers" unless @providers.nil? || @providers.empty?
      msg << ', incl. adapter' unless @adapter.nil?
    end
  end
end
