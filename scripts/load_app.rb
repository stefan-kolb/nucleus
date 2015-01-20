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
require 'excon'
require 'request_store'


# configuration
require_all 'config'

# models
require_all 'app/models'

# core
require_all 'app/core'

# adapters
require_all 'app/adapters'

# rack middleware
require_all 'app/middleware'

# api
require_all 'app/api'