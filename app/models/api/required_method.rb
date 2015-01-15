module Paasal
  module API

    # This class represents a method that is required by an API version.
    #
    # @author Cedric Röck (cedric.roeck@gmail.com)
    class RequiredMethod
      include Kwalify::Util::HashLike

      attr_accessor :name             # text

      # Initialize the RequiredMethod.
      # @param [Hash] hash the options to create the RequiredMethod
      # @option hash [String] :name The method's name
      def initialize(hash=nil)
        if hash.nil?
          return
        end
        @name = hash['name']
      end

    end
  end
end