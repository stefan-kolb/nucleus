$LOAD_PATH.unshift('lib')

# configuration
require 'logger'
require 'configatron/core'
require 'ext/kernel'
require_relative '../config/paasal'

# make sure we have a logging directory
unless paasal_config.logging.key?(:path)
  paasal_config.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log'))
end
