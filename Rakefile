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

      title = line.delete('#').strip
      href = title.tr(' ', '-').downcase
      puts '  ' * (line.count('#') - 1) + "* [#{title}](\##{href})"
    end
  end
end

desc 'Record all adapter tests'
task :record do
  # http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/record-modes
  ENV['VCR_RECORD_MODE'] = 'once'
  # recording only valid for adapter tests
  Rake::Task['spec:suite:adapters'].invoke
end

namespace :record do
  FileList['spec/adapter/v1/**'].each do |file|
    next unless File.directory?(file)
    adapter = File.basename(file)

    desc "Record #{adapter} adapter tests"
    RSpec::Core::RakeTask.new(adapter) do |t|
      # new_episodes
      ENV['VCR_RECORD_MODE'] = 'once'
      t.pattern = "spec/adapter/v1/#{adapter}/*_spec.rb"
      t.verbose = true
    end
  end
end

task :environment do
  ENV['RACK_ENV'] ||= 'development'
  require 'configatron'
  require 'nucleus/scripts/setup_config'
  nucleus_config.logging.level = Logger::Severity::ERROR
  require 'nucleus_api/scripts/load_api'
  require 'nucleus_api/scripts/initialize_api'
end

task routes: :environment do
  Nucleus::API::RootAPI.routes.each do |route|
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
  response = Nucleus::API::RootAPI.call(
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/schema',
    'rack.input' => StringIO.new)[2].body[0]
  json = JSON.parse(response)
  puts JSON.pretty_generate(json)
end

begin
  require 'yard'
  DOC_FILES = %w(lib/**/*.rb).freeze

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = DOC_FILES
  end

  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files = DOC_FILES
      t.options = ['-o', '../nucleus.doc/docs', '--title', "Nucleus #{Nucleus::VERSION} Documentation"]
    end

    desc 'Check out gh-pages.'
    task :checkout do
      dir = File.join(__dir__, '..', 'nucleus.doc')
      unless Dir.exist?(dir)
        Dir.mkdir(dir)
        Dir.chdir(dir) do
          system('git init')
          system('git remote add origin git@github.com:stefan-kolb/nucleus.git')
          system('git pull')
          system('git checkout gh-pages')
        end
      end
    end

    desc 'Generate and publish YARD docs to GitHub pages.'
    task publish: %w(doc:pages:checkout doc:pages) do
      Dir.chdir(File.join(__dir__, '..', 'nucleus.doc')) do
        system('git checkout gh-pages')
        system('git add .')
        system('git add -u')
        system("git commit -m 'Generating docs for version #{Nucleus::VERSION}.'")
        system('git push origin gh-pages')
      end
    end
  end
rescue LoadError
  puts 'You need to install YARD.'
end
