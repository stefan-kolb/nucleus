module Paasal
  module API
    class Versions < Grape::API
      helpers LogHelper

      format :json
      desc "Return list of all currently available API versions"
      get "/" do
        logger.debug("sample debug msg")
        {
          versions: [
              {v1:
                   {
                       state: "STABLE",
                       url: "http://#{request.host}:#{request.port}/v1/",
                       doc: "http://#{request.host}:#{request.port}/swagger/v1"
                   }
              },
              {v2:
                   {
                       state: "ALPHA",
                       url: "http://#{request.host}:#{request.port}/v2/",
                       doc: "http://#{request.host}:#{request.port}/swagger/v2"
                   }
              }
          ],
          documentation: "http://#{request.host}:#{request.port}/docs/index.html"
        }
      end
    end
  end
end