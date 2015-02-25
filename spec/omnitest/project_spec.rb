require 'spec_helper'

module Omnitest
  describe Project do
    subject(:project) { described_class.new(name: 'test', language: 'ruby', basedir: expected_project_dir) }
    let(:expected_project_dir) { 'samples/sdks/foo' }
    let(:psychic) { double('psychic') }
    let(:psychic) { double('global psychic', basedir: current_dir) }
    let(:expected_project_path) { Pathname.new(expected_project_dir) }

    before do
      subject.psychic = psychic
      Omnitest.psychic = psychic
    end

    describe '#bootstrap' do
      # Need an project that's already cloned
      let(:expected_project_dir) { 'samples/sdks/ruby' }

      it 'executes script/bootstrap' do
        task = double('task')
        expect(task).to receive(:execute)
        expect(psychic).to receive(:task).with('bootstrap').and_return(task)
        project.bootstrap
      end
    end

    describe '#clone' do
      it 'does nothing if there is no clone option' do
        expect(psychic).to_not receive(:execute)
        project.clone

        project.clone
      end

      context 'with git as a simple string' do
        it 'clones the repo specified by the string' do
          project.git = 'git@github.com/foo/bar'
          expect(psychic).to receive(:execute).with("git clone git@github.com/foo/bar -b master #{expected_project_path}")
          project.clone
        end
      end

      context 'with git as a hash' do
        it 'clones the repo specified by the repo parameter' do
          project.git = { repo: 'git@github.com/foo/bar' }
          expect(psychic).to receive(:execute).with("git clone git@github.com/foo/bar -b master #{expected_project_path}")
          project.clone
        end

        it 'clones the repo on the branch specified by the brach parameter' do
          project.git = { repo: 'git@github.com/foo/bar', branch: 'quuz' }
          expect(psychic).to receive(:execute).with("git clone git@github.com/foo/bar -b quuz #{expected_project_path}")
          project.clone
        end

        it 'clones the repo to the location specified by the to parameter' do
          project.git = { repo: 'git@github.com/foo/bar', to: 'sdks/foo' }
          expect(psychic).to receive(:execute).with('git clone git@github.com/foo/bar -b master sdks/foo')
          project.clone
        end
      end
    end
  end
end
