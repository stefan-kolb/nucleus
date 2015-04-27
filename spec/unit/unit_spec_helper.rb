require 'spec/spec_helper'
require 'memfs'

# define test suite for coverage report
SimpleCov.command_name 'spec:suite:unit'

RSpec.configure do |c|
  c.around(:each, memfs: true) do |example|
    MemFs.activate { example.run }
  end
end
