# First load the PaaSal core gem
require 'paasal'

# then load the HTTP API extension
#
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
require_rel '../ext'

# load import classes
require_rel '../import'

# persistence layer (models, stores and DAOs)
require_rel '../persistence'

# load common API classes
require_rel '../api/common'

# rack middleware
require_rel '../rack_middleware'

# api
require 'paasal_api/api/error_responses'
require_rel '../api/enums'
require_rel '../api/entities'
require_rel '../api/helpers'

# This is a workaround to properly load all swagger-documentation:
# Load each api version, but start with the protected controllers
Paasal::VersionDetector.api_versions.each do |api_version|
  require_rel "../api/versions/#{api_version}/protected"
  require_rel "../api/versions/#{api_version}"
end
# Finally load the complete API to make sure we did not miss anything
require_rel '../api'
