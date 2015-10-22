describe Nucleus::Adapters::ArchiveConverter, memfs: true do
  subject { Nucleus::Adapters::ArchiveConverter }
  let(:zip) { 'zip' }
  let(:tar_gz) { 'tar.gz' }
  let(:input_file) { File.join(Dir.tmpdir, 'archive_converter_spec_input_file.tar.gz') }
  it 'extracts, sanitizes and archives the input file' do
    sanitizer = double(Nucleus::ApplicationRepoSanitizer)
    expect(sanitizer).to receive(:sanitize).once

    extractor = double(Nucleus::ArchiveExtractor)
    expect(extractor).to receive(:extract).with(input_file, any_args, tar_gz).once

    archiver = double(Nucleus::Archiver)
    expect(archiver).to receive(:compress).with(any_args, zip).once

    expect(Nucleus::Archiver).to receive(:new) { archiver }
    expect(Nucleus::ArchiveExtractor).to receive(:new) { extractor }
    expect(Nucleus::ApplicationRepoSanitizer).to receive(:new) { sanitizer }

    # make sure working files get deleted
    expect(FileUtils).to receive(:rm_rf).once

    subject.convert(input_file, tar_gz, zip, true)
  end
end
