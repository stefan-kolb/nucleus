module Nucleus
  # The {Endpoint} model will initially be imported from +.yaml+ description files and shall be persisted
  # in the {Nucleus::DB::Store store}. The endpoint has the following properties:<br>
  # * id (String)
  # * name (String)
  # * provider (Nucleus::Provider)
  # * url (String)
  # * app_domain (String)
  # * trust (Boolean)
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class Endpoint < Nucleus::AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :provider
    attr_accessor :url # str
    attr_accessor :app_domain # str
    attr_accessor :trust # bool

    def initialize(hash = nil)
      super(hash)
      @trust = false
      return if hash.nil?
      @url = hash['url']
      @app_domain = hash['app_domain']
      @trust = hash['trust'] if hash.key?('trust')
    end
  end
end
