module Paasal
  module API

    # Requirements of an API version
    #
    # @author Cedric Röck (cedric.roeck@gmail.com)
    class Requirements
      include Kwalify::Util::HashLike

      attr_accessor :version          # text
      attr_accessor :methods          # seq

      # Initialize the API Requirement.
      # @param [Hash] hash the options to create the Requirement
      # @option hash [String] :version The API version
      # @option hash [Array<Paasal::RequiredMethod>] :methods The methods that are required to comply with the API version
      def initialize(hash=nil)
        if hash.nil?
          return
        end
        @version = hash['version']
        @methods = (v=hash['methods']) ? v.map!{|e| e.is_a?(Paasal::API::RequiredMethod) ? e : Paasal::API::RequiredMethod.new(e)} : v
      end

    end
  end
end