require 'require_all'

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
