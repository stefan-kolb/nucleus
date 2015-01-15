#########################
### Setup Application ###
#########################

# Load application
require_relative 'scripts/load_app'
# Initialize the application
require_relative 'scripts/initialize'

#########################
### Setup API Loggers ###
#########################

# Prepare logging directory
root = ::File.dirname(__FILE__)
logDir = ::File.join(root,'log')
FileUtils.mkdir_p(logDir) unless File.directory?(logDir)
# Setup request logging for the past 7 days
logger = Logger.new(::File.join(root,'log','requests.log'), 'daily', 7)

#########################
### Setup Rack Server ###
#########################

# X-Request-ID
use Paasal::Rack::RequestId

# Apply request logger, which includes the X-Request-ID
use Rack::AccessLogger, logger

# log error stacktraces to a dedicated file
use Paasal::Rack::ErrorRequestLogger, ::File.join('log/error.log')

# include to deal with environments that do NOT support the DELETE, PATCH, PUT methods
# use Rack::MethodOverride

# Serve our index file by default
use Rack::Static , :urls => { "/docs" => "redirect.html" } , :root => "public/swagger-ui"

run Rack::URLMap.new( {
                          "/" => Paasal::API::Base.new,
                          "/docs"    => Rack::Directory.new( "public/swagger-ui" )
                      } )