begin
  # Shutdown hook to cleanup the API
  require 'paasal_api/scripts/shutdown_api'

  # TODO: likely to be removed when using the core gem and its adapter resolver
  require 'paasal/scripts/initialize'
  require 'paasal_api/scripts/initialize_api_config'
  require 'paasal_api/scripts/initialize_daos'
  require 'paasal/scripts/finalize'
rescue Paasal::StartupError => e
  log.error "PaaSal API startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
