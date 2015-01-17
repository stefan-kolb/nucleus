module Paasal
  class Endpoint < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :provider
    attr_accessor :name             # text
    attr_accessor :url              # str

    def initialize(hash=nil)
      if hash.nil?
        return
      end
      @name = hash['name']
      @url = hash['url']
      @id = hash['id']
    end

    def get_representation
      msg = "Endpoint: #{@name}"
      unless @url.nil? || @url.empty?
        msg << " [#{@url}]"
      end
    end

  end
end
