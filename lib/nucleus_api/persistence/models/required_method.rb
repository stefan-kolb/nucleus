module Paasal
  module API
    # This class represents a method that is required by an API version.<br>
    # The method name and the required arguments were listed and imported from the +requirements.yaml+ file.
    # An adapter of the API version the {RequiredMethod} belongs to, must implement this method with the
    # identical arity to be accepted as Nucleus compliant adapter.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    # @since 0.1.0
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
        return if hash.nil?
        @name = hash['name']
        @arguments = hash['arguments']
      end
    end
  end
end
