require 'spec/unit/unit_spec_helper'
require 'kwalify'

describe 'YAML requirements schema' do
  before :all do
    meta_validator = Kwalify::MetaValidator.instance
    @parser = Kwalify::Yaml::Parser.new(meta_validator)
  end

  it 'does not produce errors' do
    # NOTE may not work with different working dir
    @parser.parse_file(File.expand_path('schemas/api.requirements.schema.yml'))
    errors = @parser.errors
    expect(errors).to match_array([])
  end
end
