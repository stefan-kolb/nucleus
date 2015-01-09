require './app'

# Prepare logging directory
root = ::File.dirname(__FILE__)
logDir = ::File.join(root,'log')
FileUtils.mkdir_p(logDir) unless File.directory?(logDir)
# Setup request logging for the past 7 days
logger = Logger.new(::File.join(root,'log','requests.log'), 'daily', 7)

##################
### Setup Rack ###
##################

# reload on file changes
use Rack::Reloader, 0

# apply logger to Rack
use Rack::CommonLogger, logger

# Serve our index file by default
use Rack::Static , :urls => { "/docs" => "redirect.html" } , :root => "public/swagger-ui"

run Rack::URLMap.new( {
                          "/" => Paasal::API::Base.new,
                          "/docs"    => Rack::Directory.new( "public/swagger-ui" )
                      } )