require 'spec/unit/unit_spec_helper'

describe Nucleus::Adapters::FileManager, memfs: true do
  let(:dir) { File.join(Dir.tmpdir, 'file_manager_load_file_test_dir') }
  let(:file) { File.join(dir, 'file_manager_load_file_test') }
  let(:contents) { 'Heja BVB, Heja BVB, Heja Heja BVB' }

  # make sure file is deleted before the next attempt
  before(:each) { FileUtils.rm_rf(dir) }

  describe '#load_file' do
    before do
      FileUtils.mkdir_p(dir)
      File.open(file, 'wb') { |f| f.write contents }
      @result = Nucleus::Adapters::FileManager.load_file(file)
    end
    it 'returns the actual file contents' do
      expect(@result.read).to eql(contents)
    end
    it 'returns a StringIO object' do
      expect(@result).to be_a(StringIO)
    end
  end

  describe '#save_file_from_data' do
    let(:io) { StringIO.new(contents) }
    let(:md5) { Digest::MD5.hexdigest(contents) }
    context 'file already exists' do
      context 'and force: false' do
        let(:force) { false }
        before { FileUtils.mkdir_p(dir) }
        it 'fails if the file already exists' do
          # prepare already existing file
          File.open(file, 'wb') { |f| f.write contents }

          expect do
            Nucleus::Adapters::FileManager.save_file_from_data(file, io, force)
          end.to raise_error(Nucleus::FileExistenceError)
        end

        it 'fails if the file already exists but content is different than anticipated' do
          # prepare already existing file
          File.open(file, 'wb') { |f| f.write StringIO.new("#{contents} - manipulated") }

          expect do
            Nucleus::Adapters::FileManager.save_file_from_data(file, io, force, md5)
          end.to raise_error(ArgumentError)
        end

        it 'succeeds if the file already exists and has the anticipated contents' do
          # prepare already existing file
          File.open(file, 'wb') { |f| f.write contents }

          # call
          Nucleus::Adapters::FileManager.save_file_from_data(file, io, force, md5)

          # expect file exists with valid content
          expect(File.exist?(file)).to eql(true)
          expect(File.read(file)).to eql(contents)
        end
      end

      context 'and force: true' do
        let(:force) { true }
        it 'succeeds' do
          # call
          Nucleus::Adapters::FileManager.save_file_from_data(file, io, force)
          # expect file exists with valid content
          expect(File.exist?(file)).to eql(true)
          expect(File.read(file)).to eql(contents)
        end
      end
    end

    context 'file does not exist yet' do
      it 'succeeds if the file already exists' do
        # call
        Nucleus::Adapters::FileManager.save_file_from_data(file, io)
        # expect file exists with valid content
        expect(File.exist?(file)).to eql(true)
        expect(File.read(file)).to eql(contents)
      end

      it 'succeeds' do
        # call
        Nucleus::Adapters::FileManager.save_file_from_data(file, io)
        # expect file exists with valid content
        expect(File.exist?(file)).to eql(true)
        expect(File.read(file)).to eql(contents)
      end
    end
  end
end
