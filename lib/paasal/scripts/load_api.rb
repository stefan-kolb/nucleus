# Grape frameworks
require 'grape'
require 'grape-entity'
require 'grape-swagger'

# faye is used to fetch logs from cloud foundry, using websocket communication
require 'rack/stream'

#
# Now we start loading the HTTP API
#

# require all patched classes for the API
require_rel '../api_ext'

# load common API classes
require_rel '../api/common'

# rack middleware
require_rel '../api/rack_middleware'

# api
require 'paasal/api/error_responses'
require_rel '../api/entities'
require_rel '../api/helpers'

# This is a workaround to properly load all swagger-documentation:
# Load each api version, but start with the protected controllers
Paasal::ApiDetector.api_versions.each do |api_version|
  require_rel "../api/versions/#{api_version}/protected"
  require_rel "../api/versions/#{api_version}"
end
# Finally load the complete API to make sure we did not miss anything
require_rel '../api'
