module Rack
  class Lint
    def check_status(_status)
      # allow any kind of HTTP status, especially the -1 that is used by rack-stream to serve chunked requests
      true
    end
  end
end
