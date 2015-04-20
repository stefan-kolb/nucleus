module Paasal
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Provider < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :vendor
    attr_accessor :name             # text
    attr_accessor :endpoints        # seq

    def initialize(hash = nil)
      return if hash.nil?
      @name = hash['name']
      @id = hash['id']
      @endpoints = []

      return unless hash.key?('endpoints')
      @endpoints = hash['endpoints'].map! { |e| e.is_a?(Paasal::Endpoint) ? e : Paasal::Endpoint.new(e) }
    end
  end
end
