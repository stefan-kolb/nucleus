# Implement shutdown actions, tidy up the DB
at_exit do
  puts '-----------------------------------------------', ''
  puts 'Cleaning up...'

  # delete the SSHHandler generated files
  puts '... delete SSH files ...'
  nucleus_config.ssh.handler.cleanup if nucleus_config.key?(:ssh) && nucleus_config.ssh.key?(:handler)

  puts '... done!'
end
