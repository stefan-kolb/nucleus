#########################
### Setup Application ###
#########################

# Load configuration
require_relative 'scripts/load_config'
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

# redirect to the documentation, but do NOT call the index directly
use Rack::Static, :urls => {'/docs' => 'redirect.html'}, :root => 'public/swagger-ui'
# we do not want robots to scan our API
use Rack::Static, :urls => {'/robots.txt' => 'robots.txt'}, :root => 'public'
#use Rack::Static , :urls => { "/" => "index.html" } , :root => "public/swagger-ui", :index => "redirect.html"

run Rack::URLMap.new(
        {
            # serve the dynamic API
            '/' => Paasal::API::RootAPI.new,
            '/api' => Paasal::API::RootAPI.new,
            # serves the swagger-ui
            '/docs' => Rack::Directory.new('public/swagger-ui')
        })
