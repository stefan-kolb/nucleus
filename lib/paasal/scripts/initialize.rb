include Paasal::Logging

begin
  # Shutdown hook to cleanup
  require 'paasal/scripts/shutdown'
rescue Paasal::StartupError => e
  log.error "Application startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
