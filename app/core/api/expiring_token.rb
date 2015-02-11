module Paasal
  module Adapters
    class ExpiringToken
      attr_reader :token
      attr_reader :expires

      def initialize(token, expires)
        @token = token
        @expires = expires
      end

      # Checks if the token is expired.
      # @return [true, false] true if the token is expired, false if it is still valid
      def expired?
        @expires >= Time.now
      end

      def to_s
        @token
      end
    end
  end
end
