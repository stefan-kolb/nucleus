# configuration
require 'logger'
require 'configatron/core'
require 'paasal/ext/kernel'
require_relative '../../../config/paasal_config'

# make sure we have a logging directory
unless paasal_config.logging.key?(:path)
  paasal_config.logging.path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'log'))
end
