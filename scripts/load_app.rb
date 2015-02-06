$LOAD_PATH.unshift('lib')

require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'require_all'
require 'logger'
require 'kwalify'
require 'daybreak'
require 'tmpdir'
require 'securerandom'
require 'excon'
require 'request_store'

# models
require_all 'app/models'

# core
require_all 'app/core'

# adapters
require_all 'app/adapters'

# rack middleware
require_all 'app/middleware'

# api
require_all 'app/api/entities'
require_all 'app/api/helpers'

# This is a workaround to properly load all swagger-documentation:
# Load each api version, but start with the protected controllers
Paasal::ApiDetector.api_versions.each do |api_version|
  require_all "app/api/versions/#{api_version}/protected"
  require_all "app/api/versions/#{api_version}"
end
# Finally load the complete API to make sure we did not miss anything
require_all 'app/api'
