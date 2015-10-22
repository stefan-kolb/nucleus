include Nucleus::Logging

begin
  # Shutdown hook to cleanup
  require 'paasal/scripts/shutdown'
rescue Nucleus::StartupError => e
  log.error "Application startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
