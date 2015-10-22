require 'spec/unit/unit_spec_helper'

describe Nucleus::Adapters::GitDeployer do
  let(:repo_name) { 'my_repository' }
  let(:repo_url) { 'http://repo.example.org' }
  let(:user_email) { 'myuser@example.org' }
  let(:repo) { double(Git::Base) }
  let(:zip) { 'zip' }
  let(:file) { File.join('random', 'file', 'path') }

  it '#deploy fails early with invalid format' do
    subject = Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email)
    extractor = double(Nucleus::ArchiveExtractor)
    expect(Nucleus::ArchiveExtractor).to receive(:new).with(any_args).once { extractor }
    # we assume format is supported
    expect(extractor).to receive(:supports?).with(kind_of(String)).once { false }
    # call should fail
    expect { subject.deploy(nil, 'xyz') }.to raise_error(Nucleus::Errors::AdapterRequestError)
  end

  describe 'repository actions' do
    before do
      # every action needs to clone the repository
      expect(Git).to receive(:clone).with(repo_url, repo_name, path: kind_of(String)).once { repo }
      # verify cleanup is performed for each method call
      expect(FileUtils).to receive(:rm_rf).with(File.join(Dir.tmpdir, repo_name)).once
    end

    describe '#download' do
      let!(:exclude_git) { true }

      context 'with master branch' do
        subject { Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email) }
        let(:repo_branch) { 'master' }
        it 'returns archived repository' do
          # verify archiver is called to return the response
          archiver = double(Nucleus::Archiver)
          expect(Nucleus::Archiver).to receive(:new).with(exclude_git) { archiver }
          expect(archiver).to receive(:compress).with(kind_of(String), zip).once { 'response' }

          # execute the call
          response = subject.download(zip, exclude_git)
          expect(response).to eql('response')
        end
      end

      context 'with nucleus branch' do
        let(:repo_branch) { 'nucleus' }
        subject { Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email, repo_branch) }
        it 'returns archived repository' do
          branch_mock = double(Git::Branch)
          expect(repo).to receive(:branch).with(repo_branch).once { branch_mock }
          expect(repo).to receive(:checkout).with(branch_mock).once { repo }

          # verify archiver is called to return the response
          archiver = double(Nucleus::Archiver)
          expect(Nucleus::Archiver).to receive(:new).with(exclude_git) { archiver }
          expect(archiver).to receive(:compress).with(kind_of(String), zip).once { 'response' }

          # execute the call
          response = subject.download(zip, exclude_git)
          expect(response).to eql('response')
        end

        it 'returns archived repository even if master did not contain any commit' do
          # branch fails for master without commits
          expect(repo).to receive(:branch).with(repo_branch).once { fail StandardError, 'No commit for master' }
          # then we rely on the fallback, checkout new branch
          expect(repo).to receive(:checkout).with(repo_branch, new_branch: true).once { repo }

          # verify archiver is called to return the response
          archiver = double(Nucleus::Archiver)
          expect(Nucleus::Archiver).to receive(:new).with(exclude_git) { archiver }
          expect(archiver).to receive(:compress).with(kind_of(String), zip).once { 'response' }

          # execute the call
          response = subject.download(zip, exclude_git)
          expect(response).to eql('response')
        end
      end
    end

    describe '#trigger_build' do
      # set username and email
      before { expect(repo).to receive(:config).with(kind_of(String), kind_of(String)).twice }

      it 'succeeds for master branch' do
        subject = Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email)
        expect(repo).to receive(:add).with(all: true).once
        expect(repo).to receive(:commit).with(kind_of(String)).once
        expect(repo).to receive(:repack).with(no_args).once
        expect(repo).to receive(:push).with(kind_of(String), 'master', force: true).once

        # there shall be the attempt to write a file to the repository
        expect(Nucleus::Adapters::FileManager).to receive(:save_file_from_data).with(any_args).once
        # trigger the method
        subject.trigger_build
      end

      it 'succeeds for nucleus branch' do
        subject = Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email, 'nucleus')
        expect(repo).to receive(:add).with(all: true).once
        expect(repo).to receive(:commit).with(kind_of(String)).once
        expect(repo).to receive(:repack).with(no_args).once
        expect(repo).to receive(:push).with(kind_of(String), 'nucleus', force: true).once

        branch_mock = double(Git::Branch)
        expect(repo).to receive(:branch).with('nucleus').once { branch_mock }
        expect(repo).to receive(:checkout).with(branch_mock).once { repo }

        # there shall be the attempt to write a file to the repository
        expect(Nucleus::Adapters::FileManager).to receive(:save_file_from_data)
        # trigger the method
        subject.trigger_build
      end
    end

    describe '#deploy', memfs: true do
      before { expect(repo).to receive(:config).with(kind_of(String), kind_of(String)).twice }
      context 'with master branch' do
        let(:repo_branch) { 'master' }
        subject { Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email) }

        describe 'fails' do
          it 'if no files were extracted' do
            extractor = double(Nucleus::ArchiveExtractor)
            expect(Nucleus::ArchiveExtractor).to receive(:new).once { extractor }
            # we assume format is supported
            expect(extractor).to receive(:supports?).with(kind_of(String)).once { true }
            # assumes number of extracted files
            expect(extractor).to receive(:extract).with(file, kind_of(String), zip) { 0 }

            # write files to disk, as the extractor would do
            repo_dir = File.join(Dir.tmpdir, repo_name)
            git_dir = File.join(repo_dir, '.git')
            FileUtils.mkdir_p(git_dir)
            FileUtils.touch(File.join(git_dir, 'some_git_file.txt'))

            # make sure files actually exist
            expect(File.file?(File.join(git_dir, 'some_git_file.txt'))).to eql(true)
            expect(File.directory?(git_dir)).to eql(true)

            # call should fail
            expect { subject.deploy(file, zip) }.to raise_error(Nucleus::Errors::AdapterRequestError)
          end
        end

        it 'succeeds' do
          expect(repo).to receive(:add).with(all: true).once
          expect(repo).to receive(:commit).with(kind_of(String)).once
          expect(repo).to receive(:repack).with(no_args).once
          expect(repo).to receive(:push).with(kind_of(String), repo_branch, force: true).once

          extractor = double(Nucleus::ArchiveExtractor)
          expect(Nucleus::ArchiveExtractor).to receive(:new).once { extractor }
          # we assume format is supported
          expect(extractor).to receive(:supports?).with(kind_of(String)).once { true }
          # assumes number of extracted files
          expect(extractor).to receive(:extract).with(file, kind_of(String), zip) { 9 }

          # write files to disk, as the extractor would do
          repo_dir = File.join(Dir.tmpdir, repo_name)
          git_dir = File.join(repo_dir, '.git')
          other_dir = File.join(repo_dir, 'another_dir')
          FileUtils.mkdir_p(git_dir)
          FileUtils.mkdir_p(other_dir)
          FileUtils.touch(File.join(repo_dir, 'file_1.txt'))
          FileUtils.touch(File.join(other_dir, 'file_2.txt'))
          FileUtils.touch(File.join(git_dir, 'some_git_file.txt'))

          # make sure files actually exist
          expect(File.file?(File.join(repo_dir, 'file_1.txt'))).to eql(true)
          expect(File.file?(File.join(other_dir, 'file_2.txt'))).to eql(true)
          expect(File.file?(File.join(git_dir, 'some_git_file.txt'))).to eql(true)
          expect(File.directory?(git_dir)).to eql(true)
          expect(File.directory?(other_dir)).to eql(true)

          # expect(Find).to receive(:find).with(kind_of(String)).once
          expect(FileUtils).to receive(:rm_rf).with(other_dir).once.and_call_original
          expect(FileUtils).to receive(:rm_f).with(File.join(repo_dir, 'file_1.txt')).once.and_call_original

          sanitizer = double(Nucleus::ApplicationRepoSanitizer)
          expect(Nucleus::ApplicationRepoSanitizer).to receive(:new).once { sanitizer }
          # we assume format is supported
          expect(sanitizer).to receive(:sanitize).with(kind_of(String)).once

          # call should succeed
          subject.deploy(file, zip)

          # normal files should be deleted
          expect(File.exist?(File.join(repo_dir, 'file_1.txt'))).to eql(false)
          expect(File.exist?(File.join(other_dir, 'file_2.txt'))).to eql(false)
          expect(File.exist?(other_dir)).to eql(false)

          # whereas git files should still exist
          expect(File.exist?(File.join(git_dir, 'some_git_file.txt'))).to eql(true)
          expect(File.exist?(git_dir)).to eql(true)
        end
      end

      context 'with nucleus branch' do
        let(:repo_branch) { 'nucleus' }
        subject { Nucleus::Adapters::GitDeployer.new(repo_name, repo_url, user_email, repo_branch) }
        it 'succeeds' do
          expect(repo).to receive(:add).with(all: true).once
          expect(repo).to receive(:commit).with(kind_of(String)).once
          expect(repo).to receive(:repack).with(no_args).once
          expect(repo).to receive(:push).with(kind_of(String), repo_branch, force: true).once

          branch_mock = double(Git::Branch)
          expect(repo).to receive(:branch).with(repo_branch).once { branch_mock }
          expect(repo).to receive(:checkout).with(branch_mock).once { repo }

          extractor = double(Nucleus::ArchiveExtractor)
          expect(Nucleus::ArchiveExtractor).to receive(:new).once { extractor }
          # we assume format is supported
          expect(extractor).to receive(:supports?).with(kind_of(String)).once { true }
          # assumes number of extracted files
          expect(extractor).to receive(:extract).with(file, kind_of(String), zip) { 9 }

          # write files to disk, as the extractor would do
          repo_dir = File.join(Dir.tmpdir, repo_name)
          git_dir = File.join(repo_dir, '.git')
          other_dir = File.join(repo_dir, 'another_dir')
          FileUtils.mkdir_p(git_dir)
          FileUtils.mkdir_p(other_dir)
          FileUtils.touch(File.join(repo_dir, 'file_1.txt'))
          FileUtils.touch(File.join(other_dir, 'file_2.txt'))
          FileUtils.touch(File.join(git_dir, 'some_git_file.txt'))

          # make sure files actually exist
          expect(File.file?(File.join(repo_dir, 'file_1.txt'))).to eql(true)
          expect(File.file?(File.join(other_dir, 'file_2.txt'))).to eql(true)
          expect(File.file?(File.join(git_dir, 'some_git_file.txt'))).to eql(true)
          expect(File.directory?(git_dir)).to eql(true)
          expect(File.directory?(other_dir)).to eql(true)

          # expect(Find).to receive(:find).with(kind_of(String)).once
          expect(FileUtils).to receive(:rm_rf).with(other_dir).once.and_call_original
          expect(FileUtils).to receive(:rm_f).with(File.join(repo_dir, 'file_1.txt')).once.and_call_original

          sanitizer = double(Nucleus::ApplicationRepoSanitizer)
          expect(Nucleus::ApplicationRepoSanitizer).to receive(:new).once { sanitizer }
          # we assume format is supported
          expect(sanitizer).to receive(:sanitize).with(kind_of(String)).once

          # call should succeed
          subject.deploy(file, zip)

          # normal files should be deleted
          expect(File.exist?(File.join(repo_dir, 'file_1.txt'))).to eql(false)
          expect(File.exist?(File.join(other_dir, 'file_2.txt'))).to eql(false)
          expect(File.exist?(other_dir)).to eql(false)

          # whereas git files should still exist
          expect(File.exist?(File.join(git_dir, 'some_git_file.txt'))).to eql(true)
          expect(File.exist?(git_dir)).to eql(true)
        end
      end
    end
  end
end
