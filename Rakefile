import 'tasks/compatibility.rake'
import 'tasks/evaluation.rake'
import 'spec/test_suites.rake'

require 'rake'
require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rainbow/ext/string' unless String.respond_to?(:color)
require 'rubocop/rake_task'

RuboCop::RakeTask.new

# first check code style, then execute the tests
task default: [:rubocop, :spec]

# map spec task to all test suites
task :spec do
  # first, run all tests
  Rake::Task['spec:suite:all'].invoke
  # if on the CI system, push coverage report to codeclimate
  if ENV['CODECLIMATE_REPO_TOKEN']
    require 'simplecov'
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter::Formatter.new.format(SimpleCov.result)
  end
end

task :doc_toc do
  File.open('README.md', 'r') do |f|
    f.each_line do |line|
      forbidden_words = ['Table of contents', 'define', 'pragma']
      next if !line.start_with?('#') || forbidden_words.any? { |w| line =~ /#{w}/ }

      title = line.gsub('#', '').strip
      href = title.gsub(' ', '-').downcase
      puts '  ' * (line.count('#') - 1) + "* [#{title}](\##{href})"
    end
  end
end

task :record do
  ENV['VCR_RECORD_MODE'] = 'all'
  # recording only valid for adapter tests
  Rake::Task['spec:suite:adapters'].invoke
end

task :environment do
  ENV['RACK_ENV'] ||= 'development'
  require 'configatron'
  require 'paasal/scripts/setup_config'
  paasal_config.logging.level = Logger::Severity::ERROR
  require 'paasal_api/scripts/load_api'
  require 'paasal_api/scripts/initialize_api'
end

task routes: :environment do
  Paasal::API::RootAPI.routes.each do |route|
    next if route.nil? || route.route_method.nil?
    method = route.route_method.ljust(10)
    path = route.route_path
    version = route.instance_variable_get(:@options)[:version]
    path = path.gsub(/:version/, version) unless version.nil?
    puts "    #{method} #{path} - [#{version}]"
  end
end

task schema_v1: :environment do
  require 'json'
  response = Paasal::API::RootAPI.call(
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/schema',
    'rack.input' => StringIO.new)[2].body[0]
  json = JSON.parse(response)
  puts JSON.pretty_generate(json)
end

begin
  require 'yard'
  DOC_FILES = %w(app/**/*.rb lib/**/*.rb README.md)

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = DOC_FILES
  end

  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files   = DOC_FILES
      t.options = ['-o', '../paasal.doc/docs', '--title', "PaaSal #{Paasal::VERSION} Documentation"]
    end

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
    task publish: %w(doc:pages:checkout doc:pages) do
      Dir.chdir(File.dirname(__FILE__) + '/../paasal.doc') do
        system('git checkout gh-pages')
        system('git add .')
        system('git add -u')
        system("git commit -m 'Generating docs for version #{Paasal::VERSION}.'")
        system('git push origin gh-pages')
      end
    end
  end
rescue LoadError
  puts 'You need to install YARD.'
end
