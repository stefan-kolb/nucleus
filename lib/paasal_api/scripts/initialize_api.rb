begin
  # Shutdown hook to cleanup the API
  require 'paasal_api/scripts/shutdown_api'

  require 'paasal/scripts/initialize'

  # Apply the default API descriptions
  nucleus_config.api.title = 'Nucleus - Platform as a Service abstraction layer API'
  nucleus_config.api.description = 'Nucleus allows to manage multiple PaaS providers with just one API to be used'
  nucleus_config.api.contact = 'stefan.kolb@uni-bamberg.de'
  nucleus_config.api.license = 'MIT'
  nucleus_config.api.license_url = 'http://opensource.org/licenses/MIT'
  nucleus_config.api.terms_of_service_url = 'API still under development, no guarantees (!)'

  # include the configuration of the project to overwrite the home dir config
  project_dir_config = '../../../config/nucleus_config.rb'
  if File.exist?(File.expand_path(project_dir_config, __dir__))
    puts "Applying configuration from: #{File.expand_path(project_dir_config, __dir__)}"
    require_relative project_dir_config
  end

  # now load the configuration values
  require 'paasal/scripts/initialize_config_defaults'

  require 'paasal_api/scripts/initialize_api_customizations'

  require 'paasal_api/scripts/initialize_daos'

  # finalize so that the configuration is locked
  require 'paasal/scripts/finalize'
rescue Paasal::StartupError => e
  log.error "Nucleus API startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
