$LOAD_PATH.unshift('lib')

require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'require_all'
require 'logger'
require 'kwalify'
require 'daybreak'
require 'lmdb'
require 'moneta'
require 'tmpdir'
require 'find'
require 'filesize'
require 'time'
require 'securerandom'

require 'rack/body_proxy'
require 'rack/utils'
require 'rack/response'
require 'rack/auth/basic'

# Currently we need excon AND rest_client, due to excon not supporting multipart requests. See also:
# https://github.com/excon/excon/issues/353
require 'excon'
require 'rest_client'
# faye is used to fetch logs from cloud foundry, using websocket communication
require 'faye/websocket'
require 'rack/stream'
require 'protobuf'
require 'eventmachine'
require 'em-http'

require 'request_store'
require 'git'
require 'mime-types'

# require archive dependencies
require 'zip'
require 'zlib'
require 'rubygems/package'

# OS detection
require 'os'

# require all patched classes
require_all 'lib/ext'

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
