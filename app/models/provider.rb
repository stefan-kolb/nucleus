module Paasal
  class Provider < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :name             # text
    attr_accessor :endpoints        # seq

    def initialize(hash = nil)
      if hash.nil?
        return
      end
      @name = hash['name']
      @id = hash['id']

      v = hash['endpoints']
      if v
        @endpoints = v.map! { |e| e.is_a?(Paasal::Endpoint) ? e : Paasal::Endpoint.new(e) }
      else
        @endpoints
      end
    end

    def representation
      msg = "Provider: #{@name}"
      msg << ", #{@endpoints.size} endpoints" unless @endpoints.nil? || @endpoints.empty?
    end
  end
end
