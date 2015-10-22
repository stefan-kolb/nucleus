# Implement API shutdown actions, tidy up the DB
at_exit do
  puts '-----------------------------------------------', ''
  puts 'Cleaning up the API...'

  if !nucleus_config.db.key?(:delete_on_shutdown) || nucleus_config.db.delete_on_shutdown
    if File.exist?(nucleus_config.db.path) && File.directory?(nucleus_config.db.path)
      FileUtils.rm_rf(nucleus_config.db.path)
    end
    puts '... DB store successfully deleted' unless File.exist?(nucleus_config.db.path)
  end
  puts '... done!'
end
