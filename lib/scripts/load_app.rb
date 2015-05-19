require 'require_all'

# Grape frameworks
require 'grape'
require 'grape-entity'
require 'grape-swagger'

# actually more native
require 'tmpdir'
require 'find'
require 'time'
require 'securerandom'
require 'logger'

# database
require 'moneta'
require 'daybreak'
require 'lmdb'

# schema
require 'kwalify'

# serialization
require 'oj'

# SSH keys
require 'sshkey'

# Http clients, ...
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

# others
require 'request_store'
require 'git'
require 'mime-types'

# require archive dependencies
require 'zip'
require 'zlib'
require 'rubygems/package'

# OS detection
require 'os'
# Root directory
require 'root_dir'

# require all patched classes
require_all "#{Paasal.root}/lib/ext"

# core
require_all "#{Paasal.root}/app/core"

# persistence layer (models, stores and DAOs)
require_all "#{Paasal.root}/app/persistence"

# rack middleware
require_all "#{Paasal.root}/app/rack_middleware"

# api
require 'api/error_responses'
require_all "#{Paasal.root}/app/api/entities"
require_all "#{Paasal.root}/app/api/helpers"

# adapters
require_all "#{Paasal.root}/app/adapters"

# This is a workaround to properly load all swagger-documentation:
# Load each api version, but start with the protected controllers
Paasal::ApiDetector.api_versions.each do |api_version|
  require_all "#{Paasal.root}/app/api/versions/#{api_version}/protected"
  require_all "#{Paasal.root}/app/api/versions/#{api_version}"
end
# Finally load the complete API to make sure we did not miss anything
require_all "#{Paasal.root}/app/api"
