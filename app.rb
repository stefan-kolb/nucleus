$LOAD_PATH.unshift('lib')

require 'grape'
require 'grape-swagger'
require 'require_all'
require 'logger'
require 'configatron'

# models
#require_all 'app/models'

# views
#set :views, Proc.new { File.join(root, 'app/views') }
#not_found { erb :'404', :layout => false }
#error { erb :'500', :layout => false }

# config
require_all 'config'

# common
require_all 'app/common'

# adapters
require_all 'app/adapters'

# api
require_all 'app/api'

# Lock the configuration, so it can't be manipulated
configatron.lock!
puts 'Loaded and locked configuration!'
puts "Log-Level: #{configatron.logging.level}"