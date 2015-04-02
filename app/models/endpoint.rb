module Paasal
  class Endpoint < Paasal::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :provider
    attr_accessor :name             # text
    attr_accessor :url              # str
    attr_accessor :app_domain       # str
    attr_accessor :trust            # bool

    def initialize(hash = nil)
      return if hash.nil?
      @name = hash['name']
      @url = hash['url']
      @app_domain = hash['app_domain']
      @id = hash['id']
      @trust = hash.key?('trust') ? hash['trust'] : false
    end

    def representation
      msg = "Endpoint: #{@name}"
      msg << " [#{@url}]" unless @url.nil? || @url.empty?
      msg << ' *trusted*' if @trust
      msg
    end
  end
end
