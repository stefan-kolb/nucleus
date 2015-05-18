# Implement shutdown actions, tidy up the DB
at_exit do
  puts '-----------------------------------------------', ''
  puts 'Cleaning up...'

  # delete the SSHHandler generated files
  paasal_config.ssh.handler.cleanup if paasal_config.key?(:ssh) && paasal_config.ssh.key?(:handler)

  if !paasal_config.db.key?(:delete_on_shutdown) || paasal_config.db.delete_on_shutdown
    if File.exist?(paasal_config.db.path) && File.directory?(paasal_config.db.path)
      FileUtils.rm_rf(paasal_config.db.path)
    end
    puts '... DB store successfully deleted' unless File.exist?(paasal_config.db.path)
  end
  puts '... done!', 'Bye :)'
end
