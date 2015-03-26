#########################
### Setup Application ###
#########################

# Setup bundler compatibility, according to: http://bundler.io/v1.9/rationale.html
require 'rubygems'
require 'bundler/setup'

# Load configuration
require './scripts/load_config'
# Load application
require './scripts/load_app'
# Initialize the application
require './scripts/initialize'

# Initialize the Rack environment
# GO TO THIS FILE TO INCLUDE MIDDLEWARE (!)
require './scripts/initialize_rack'

## finally start the application
run Paasal::Rack.app
