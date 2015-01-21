require 'spec_helper'
require 'kwalify'

describe 'The validation of the' do

  before :all do
    meta_validator = Kwalify::MetaValidator.instance
    @parser = Kwalify::Yaml::Parser.new(meta_validator)
  end

  it 'adapter schema does not produce errors' do
    # NOTE may not work with different working dir
    @parser.parse_file(File.expand_path('schemas/api.adapter.schema.yml'))
    errors = @parser.errors
    expect(errors).to match_array([])
  end

  it 'requirements schema does not produce errors' do
    # NOTE may not work with different working dir
    @parser.parse_file(File.expand_path('schemas/api.requirements.schema.yml'))
    errors = @parser.errors
    expect(errors).to match_array([])
  end

  # TODO test adapter configs

  # TODO test adapter implementations

end
