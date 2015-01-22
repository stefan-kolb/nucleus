module Paasal
  class AdapterIndexEntry
    include Kwalify::Util::HashLike

    attr_accessor :adapter_clazz
    attr_accessor :id
    attr_accessor :url

    def initialize(hash = nil)
      return if hash.nil?
      @id = hash['id']
      @url = hash['url']
      @adapter_clazz = hash['adapter_clazz']
    end
  end
end
