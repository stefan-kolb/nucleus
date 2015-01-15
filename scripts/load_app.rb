$LOAD_PATH.unshift('lib')

require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'require_all'
require 'logger'
require 'configatron'
require 'kwalify'
require 'daybreak'
require 'tmpdir'
require 'securerandom'

# Shutdown hook to cleanup
require_relative 'shutdown.rb'

# configuration
require_all 'config'

# rack middleware
require_all 'app/middleware'

# models
require_all 'app/models'

# core
require_all 'app/core'

# adapters
require_all 'app/adapters'

# api
require_all 'app/api'