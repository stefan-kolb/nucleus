# Implement shutdown actions, tidy up the DB
at_exit do
  puts '-----------------------------------------------', ''
  puts 'Cleaning up...'

  # delete the SSHHandler generated files
  puts '... delete SSH files ...'
  paasal_config.ssh.handler.cleanup if paasal_config.key?(:ssh) && paasal_config.ssh.key?(:handler)

  puts '... done!'
end
