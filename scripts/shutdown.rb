# Implement shutdown actions, tidy up the DB
at_exit do
  puts '', '-----------------------------------------------', ''
  puts 'Cleaning up...'

  if configatron.db.key?(:delete_on_shutdown) && configatron.db.delete_on_shutdown
    FileUtils.rm_rf(configatron.db.path) if File.exist?(configatron.db.path) && File.directory?(configatron.db.path)
    puts '... DB store successfully deleted' unless File.exist?(configatron.db.path)
  else
    Paasal::DB::MetaStore.new.tidy_all
  end
end
