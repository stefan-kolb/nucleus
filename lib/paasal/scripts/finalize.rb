# Lock the configuration, so it can't be manipulated
nucleus_config.lock!

puts "Rack environment: #{ENV['RACK_ENV']}" if ENV.key?('RACK_ENV')
puts 'Configuration locked!'

puts 'Initialization complete'
puts '-----------------------------------------------'
