require 'msgpack'

module VCR
  class Cassette
    class Serializers
      # The MessagePack serializer. Uses `MessagePack` internally.
      #
      # @see MessagePack
      module MessagePack
        # @private
        ENCODING_ERRORS = [ArgumentError]

        # The file extension to use for this serializer.
        #
        # @return [String] "rec"
        def self.file_extension
          'rec'
        end

        # Serializes the given hash using MessagePack.
        #
        # @param [Hash] hash the object to serialize
        # @return [String] the MessagePack string
        def self.serialize(hash)
          handle_encoding_errors do
            ::MessagePack.pack(hash)
          end
        end

        # Deserializes the given string using MessagePack.
        #
        # @param [String] string the MessagePack string
        # @return [Hash] the deserialized object
        def self.deserialize(string)
          handle_encoding_errors do
            ::MessagePack.unpack(string)
          end
        end

        private

        def self.handle_encoding_errors
          yield
        rescue *self::ENCODING_ERRORS => e
          e.message << "\nNote: Using VCR's `:preserve_exact_body_bytes` option may help prevent this error "\
            'in the future.'
          raise
        end
      end
    end
  end
end
