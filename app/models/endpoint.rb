module Paasal
  class Endpoint < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :name             # text
    attr_accessor :url              # str

    def initialize(hash=nil)
      if hash.nil?
        return
      end
      @name = hash['name']
      @url = hash['url']
    end

  end

end
