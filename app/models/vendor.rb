module Paasal
  class Vendor < Paasal::AbstractModel

    attr_accessor :name             # text
    attr_accessor :providers        # seq
    attr_accessor :adapter

    def initialize(hash=nil)
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

    def get_representation
      msg = "Vendor: #{@name}"
      unless @providers.nil? || @providers.empty?
        msg << ", #{@providers.size} providers"
      end
      unless @adapter.nil?
        msg << ', incl. adapter'
      end
    end

  end
end