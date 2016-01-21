require 'oj'

module VCR
  class Cassette
    class Serializers
      # The Oj serializer. Uses `Oj` internally.
      #
      # @see Oj
      module Oj
        # @private
        ENCODING_ERRORS = [ArgumentError].freeze

        # The file extension to use for this serializer.
        #
        # @return [String] "json"
        def self.file_extension
          'json'
        end

        # Serializes the given hash using Oj.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the JSON string
        def self.serialize(hash)
          handle_encoding_errors do
            ::Oj.dump(hash)
          end
        end

        # Deserializes the given string using Oj.
        #
        # @param [String] string the JSON string
        # @return [Hash] the deserialized object
        def self.deserialize(string)
          handle_encoding_errors do
            ::Oj.load(string)
          end
        end

        def self.handle_encoding_errors
          yield
        rescue *self::ENCODING_ERRORS => e
          e.message << "\nNote: Using VCR's `:preserve_exact_body_bytes` option may help prevent this error "\
            'in the future.'
          raise
        end

        private_class_method :handle_encoding_errors
      end
    end
  end
end
