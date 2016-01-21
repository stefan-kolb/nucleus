require 'rspec/core/rake_task'

SPEC_SUITES = [
  { id: :unit, title: 'unit tests', pattern: 'spec/unit/**/*_spec.rb' },
  { id: :adapters, title: 'adapter tests', pattern: 'spec/adapter/**/*_spec.rb' },
  { id: :integration, title: 'integration tests', pattern: 'spec/integration/**/*_spec.rb' }
].freeze

namespace :spec do
  namespace :suite do
    SPEC_SUITES.each do |suite|
      desc "Run all specs in #{suite[:title]} spec suite"
      RSpec::Core::RakeTask.new(suite[:id]) do |t|
        t.pattern = suite[:pattern]
        t.verbose = false
        t.fail_on_error = false
      end
    end
    desc 'Run all spec suites'
    task :all do
      require 'English'
      failed = []
      SPEC_SUITES.each do |suite|
        p "Running spec suite #{suite[:id]} ..."
        Rake::Task["spec:suite:#{suite[:id]}"].execute
        failed << suite[:id] unless $CHILD_STATUS.success?
      end
      fail "Spec suite#{failed.length > 1 ? 's' : ''} '#{failed.join(', ')}' failed" unless failed.empty?
    end
  end
end
