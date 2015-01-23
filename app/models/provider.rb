module Paasal
  class Provider < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :name             # text
    attr_accessor :endpoints        # seq

    def initialize(hash = nil)
      return if hash.nil?
      hash = HashWithIndifferentAccess.new hash
      @name = hash[:name]
      @id = hash[:id]
      @endpoints = []

      return unless hash.key?(:endpoints)
      @endpoints = hash[:endpoints].map! { |e| e.is_a?(Paasal::Endpoint) ? e : Paasal::Endpoint.new(e) }
    end

    def representation
      msg = "Provider: #{@name}"
      msg << ", #{@endpoints.size} endpoints" unless @endpoints.nil? || @endpoints.empty?
    end
  end
end
