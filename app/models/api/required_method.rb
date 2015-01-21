module Paasal
  module API
    # This class represents a method that is required by an API version.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    class RequiredMethod
      include Kwalify::Util::HashLike

      attr_accessor :name             # text
      attr_accessor :arguments        # int

      # Initialize the RequiredMethod.
      # @param [Hash] hash the options to create the RequiredMethod
      # @option hash [String] name The method's name
      # @option hash [String] arguments (0) The number of expected arguments for the method
      def initialize(hash = nil)
        @arguments = 0
        if hash.nil?
          return
        end
        @name = hash['name']
        @arguments = hash['arguments']
      end
    end
  end
end
