#########################
### Setup Application ###
#########################

# Setup bundler compatibility, according to: http://bundler.io/v1.9/rationale.html
require 'rubygems'
require 'bundler/setup'

# Load configuration
require 'paasal/scripts/setup_config'
# Load application
require 'paasal/scripts/load'
# Initialize the application
require 'paasal/scripts/initialize'

# Initialize the Rack environment
# GO TO THIS FILE TO INCLUDE MIDDLEWARE (!)
require 'paasal/scripts/initialize_rack'

## finally start the application
run Paasal::Rack.app
