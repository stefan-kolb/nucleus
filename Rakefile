require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec

require 'rainbow/ext/string' unless String.respond_to?(:color)
require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: [:rubocop, :spec]

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

begin
  require 'yard'
  DOC_FILES = ['app/**/*.rb', 'lib/**/*.rb', 'README.md']

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = DOC_FILES
  end

  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files   = DOC_FILES
      t.options = ['-o', '../paasal.doc/docs', '--title', "PaaSal #{Paasal::VERSION} Documentation"]
    end

    namespace :pages do
      desc 'Check out gh-pages.'
      task :checkout do
        dir = File.dirname(__FILE__) + '/../paasal.doc'
        unless Dir.exist?(dir)
          Dir.mkdir(dir)
          Dir.chdir(dir) do
            system('git init')
            system('git remote add origin git@github.com:croeck/paasal.git')
            system('git pull')
            system('git checkout gh-pages')
          end
        end
      end

      desc 'Generate and publish YARD docs to GitHub pages.'
      task :publish => ['doc:pages:checkout', 'doc:pages'] do
        Dir.chdir(File.dirname(__FILE__) + '/../paasal.doc') do
          system('git checkout gh-pages')
          system('git add .')
          system('git add -u')
          system("git commit -m 'Generating docs for version #{Paasal::VERSION}.'")
          system('git push origin gh-pages')
        end
      end
    end
  end
rescue LoadError
  puts 'You need to install YARD.'
end
