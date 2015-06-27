#########################
### Setup Application ###
#########################

# Setup bundler compatibility, according to: http://bundler.io/v1.9/rationale.html
require 'rubygems'
require 'bundler/setup'

# Load configuration
require 'paasal/scripts/setup_config'
# Load application
require 'paasal_api/scripts/load_api'
# Initialize the application
require 'paasal_api/scripts/initialize_api'

# Initialize the Rack environment
# GO TO THIS FILE TO INCLUDE MIDDLEWARE (!)
require 'paasal_api/scripts/rack_application'

## finally start the application
run Paasal::API::Rack.app
