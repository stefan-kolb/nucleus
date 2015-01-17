module Paasal
  class Provider < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :name             # text
    attr_accessor :endpoints        # seq

    def initialize(hash=nil)
      if hash.nil?
        return
      end
      @name = hash['name']
      @id = hash['id']
      @endpoints = (v=hash['endpoints']) ? v.map!{|e| e.is_a?(Paasal::Endpoint) ? e : Paasal::Endpoint.new(e)} : v
    end

    def get_representation
      msg = "Provider: #{@name}"
      unless @endpoints.nil? || @endpoints.empty?
        msg << ", #{@endpoints.size} endpoints"
      end
    end

  end
end
