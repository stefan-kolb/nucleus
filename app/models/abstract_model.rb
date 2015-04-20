module Paasal
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  # @since 0.1.0
  class AbstractModel
    include Kwalify::Util::HashLike

    attr_accessor :id
    attr_accessor :created_at
    attr_accessor :updated_at

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
