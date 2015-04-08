$LOAD_PATH.unshift('lib')

# configuration
require 'logger'
require 'configatron'
require_relative '../config/paasal'

# make sure we have a logging directory
unless configatron.logging.key?(:path)
  configatron.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))
end
