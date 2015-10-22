module Nucleus
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :id
    attr_accessor :name
    attr_accessor :created_at
    attr_accessor :updated_at

    def initialize(hash = nil)
      return if hash.nil?
      @name = hash['name']
      @id = hash['id']
    end

    def to_s
      return name if self.respond_to?('name')
      return id if id
      super.to_s
    end

    def inspect
      to_s
    end
  end
end
