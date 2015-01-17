require 'kwalify'

describe 'Adapter schema validity' do

  before :all do
    meta_validator = Kwalify::MetaValidator.instance
    @parser = Kwalify::Yaml::Parser.new(meta_validator)
  end

  it 'should have no errors' do
    # NOTE may not work with different working dir
    @parser.parse_file(File.expand_path('schemas/api.adapter.schema.yml'))
    errors = @parser.errors
    expect(errors).to match_array([])
  end

end