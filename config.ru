#########################
### Setup Application ###
#########################
require 'bundler/setup'

# Load configuration
require 'nucleus/scripts/setup_config'
# Load application
require 'nucleus_api/scripts/load_api'
# Initialize the application
require 'nucleus_api/scripts/initialize_api'

# Initialize the Rack environment
# GO TO THIS FILE TO INCLUDE MIDDLEWARE (!)
require 'nucleus_api/scripts/rack_application'

# finally start the application
run Nucleus::API::Rack.app
