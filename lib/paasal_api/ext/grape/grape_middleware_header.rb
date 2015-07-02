require 'grape/middleware/base'

module Grape
  module Middleware
    module Versioner
      class Header < Base
        # NOTE: this class is patched so that we can use a web-browser for the API
        # it removes the default media_types, eg. 'application/xml'.
        # If they were allowed no version would be passed to the middleware

        private

        def available_media_types
          available_media_types = []

          content_types.each do |extension, _media_type|
            versions.reverse_each do |version|
              available_media_types += ["application/vnd.#{vendor}-#{version}+#{extension}",
                                        "application/vnd.#{vendor}-#{version}"]
            end
            available_media_types << "application/vnd.#{vendor}+#{extension}"
          end

          available_media_types << "application/vnd.#{vendor}"
          available_media_types.flatten
        end
      end
    end
  end
end
