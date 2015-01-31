#########################
### Setup Application ###
#########################

# Load configuration
require_relative 'scripts/load_config'
# Load application
require_relative 'scripts/load_app'
# Initialize the application
require_relative 'scripts/initialize'

# Initialize all Loggers
require_relative 'scripts/initialize_loggers'

# Initialize the Rack environment
# GO TO THIS FILE TO INCLUDE MIDDLEWARE (!)
require_relative 'scripts/initialize_rack'

## finally start the application
run Paasal::Rack.app
