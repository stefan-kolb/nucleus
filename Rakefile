require 'bundler/gem_tasks'

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', 'app/**/*.rb', '*.rb']
  end
rescue LoadError
end

task :environment do
  ENV['RACK_ENV'] ||= 'development'
  require_relative 'scripts/load_app'
end

task routes: :environment do
  Paasal::API::RootAPI.routes.each do |route|
    unless route.route_method.nil?
      method = route.route_method.ljust(10)
      path = route.route_path
      version = route.instance_variable_get(:@options)[:version]
      path = path.gsub(/:version/, version) unless version.nil?
      puts "     #{method} #{path}"
    end
  end
end

task schema_v1: :environment do
  require 'json'
  response = Paasal::API::RootAPI.call(
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/v1/schema',
      'rack.input' => StringIO.new)[2].body[0]
  json = JSON.parse(response)
  puts JSON.pretty_generate(json)
end

# TODO get json schema