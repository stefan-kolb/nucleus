module Nucleus
  class StreamCallback
    include Nucleus::Logging

    attr_accessor :closed

    def initialize(stream)
      @stream = stream
      @closed = false
    end

    # Send a message via the stream to the client
    # @param [String] message content to send to the client
    def send_message(message)
      log.debug "New streamed message part: #{message}"
      @stream.chunk message
    end

    # Close the stream
    # @return [void]
    def close
      log.debug 'Close API stream, invoked by adapter callback'
      # close API stream of the Rack server unless it was already closed
      @stream.close unless @closed
    end
  end
end
