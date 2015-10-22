module Nucleus
  module API
    # Requirements of an API version.<br>
    # The required methods are collected from the +requirements.yaml+ file of an API version and their presence
    # can be verified with unit tests.<br>
    # An adapter of the API version the must implement all the methods with the correct arity to be accepted
    # as Nucleus compliant adapter.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    # @since 0.1.0
    class Requirements
      include Kwalify::Util::HashLike

      attr_accessor :version          # text
      attr_accessor :methods          # seq

      # Initialize the API Requirement.
      # @param [Hash] hash the options to create the Requirement
      # @option hash [String] :version The API version
      # @option hash [Array<Nucleus::RequiredMethod>] :methods methods that are required to comply with the API version
      def initialize(hash = nil)
        return if hash.nil?
        @version = hash['version']
        v = hash['methods']
        if v
          @methods = v.map! { |e| e.is_a?(Nucleus::API::RequiredMethod) ? e : Nucleus::API::RequiredMethod.new(e) }
        else
          @methods = v
        end
      end
    end
  end
end
