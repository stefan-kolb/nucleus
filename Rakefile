require "bundler/gem_tasks"

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', 'app/**/*.rb', '*.rb']
  end
rescue LoadError
end
