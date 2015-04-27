describe Paasal::Adapters::ArchiveConverter, memfs: true do
  subject { Paasal::Adapters::ArchiveConverter }
  let(:zip) { 'zip' }
  let(:tar_gz) { 'tar.gz' }
  let(:input_file) { File.join(Dir.tmpdir, 'archive_converter_spec_input_file.tar.gz') }
  it 'extracts, sanitizes and archives the input file' do
    sanitizer = double(Paasal::ApplicationRepoSanitizer)
    expect(sanitizer).to receive(:sanitize).once

    extractor = double(Paasal::ArchiveExtractor)
    expect(extractor).to receive(:extract).with(input_file, any_args, tar_gz).once

    archiver = double(Paasal::Archiver)
    expect(archiver).to receive(:compress).with(any_args, zip).once

    expect(Paasal::Archiver).to receive(:new) { archiver }
    expect(Paasal::ArchiveExtractor).to receive(:new) { extractor }
    expect(Paasal::ApplicationRepoSanitizer).to receive(:new) { sanitizer }

    # make sure working files get deleted
    expect(FileUtils).to receive(:rm_rf).once

    subject.convert(input_file, tar_gz, zip, true)
  end
end
