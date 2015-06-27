include Paasal::Logging

# Shutdown hook to cleanup
require 'paasal/scripts/shutdown'

begin
  require 'paasal/scripts/initialize_config'
rescue Paasal::StartupError => e
  log.error "Application startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
