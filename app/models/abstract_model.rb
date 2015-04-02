module Paasal
  class AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :id
    attr_accessor :created_at
    attr_accessor :updated_at

    def to_s
      if self.respond_to?('representation') && !@name.nil? && !@name.to_s.strip.length == 0
        return representation
      end
      super.to_s
    end

    def inspect
      if self.respond_to?('representation') && !@name.nil? && @name.to_s.strip.length > 0
        return representation
      end
      super.inspect
    end
  end
end
