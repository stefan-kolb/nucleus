# configuration
require 'logger'
require 'configatron/core'
require 'paasal/ext/kernel'
require 'paasal/os'

# import the configuration file that resides in the user's home directory as initial choice
if OS.windows?
  home_dir_config = File.expand_path(File.join(Dir.home, 'paasal', 'paasal_config.rb'))
else
  home_dir_config = File.expand_path(File.join(Dir.home, '.paasal', 'paasal_config.rb'))
end
if File.exist?(home_dir_config)
  puts "Applying configuration from: #{home_dir_config}"
  require home_dir_config
end

# include the configuration of the project to overwrite the home dir config
project_dir_config = '../../../config/paasal_config.rb'
if File.exist?(File.expand_path(project_dir_config, File.dirname(__FILE__)))
  puts "Applying configuration from: #{File.expand_path(project_dir_config, File.dirname(__FILE__))}"
  require_relative project_dir_config
end

# make sure we have a logging directory
unless paasal_config.logging.key?(:path)
  paasal_config.logging.path = File.join(__dir__, '..', '..', '..', 'log')
end
