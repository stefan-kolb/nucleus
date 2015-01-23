module Paasal
  class Endpoint < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :provider
    attr_accessor :name             # text
    attr_accessor :url              # str

    def initialize(hash = nil)
      return if hash.nil?
      hash = HashWithIndifferentAccess.new hash
      @name = hash[:name]
      @url = hash[:url]
      @id = hash[:id]
    end

    def representation
      msg = "Endpoint: #{@name}"
      msg << " [#{@url}]" unless @url.nil? || @url.empty?
    end
  end
end
