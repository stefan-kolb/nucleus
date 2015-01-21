module Paasal
  class AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :id
    attr_accessor :created_at
    attr_accessor :updated_at

    # Get the entity's key:
    # Shall be the name, but without whitespaces and in small letters
    #
    # @return [String] downcased name without whitespaces
    def key
      name.gsub(/\s+/, '-').downcase
    end

    def to_s
      if self.respond_to?('get_representation') && !@name.nil? && !@name.to_s.strip.length == 0
        return get_representation
      end
      super.to_s
    end

    def inspect
      if self.respond_to?('get_representation') && !@name.nil? && @name.to_s.strip.length > 0
        return get_representation
      end
      super.inspect
    end

  end
end
