require 'spec_helper'

module Crosstest
  describe Project do
    subject(:project) { described_class.new(name: 'test', language: 'ruby', basedir: expected_project_dir) }
    let(:expected_project_dir) { 'samples/sdks/foo' }
    let(:runner) { double('runner') }
    let(:global_runner) { double('global runner') }
    let(:expected_project_path) { Pathname.new(expected_project_dir) }

    before do
      subject.runner = runner
      Crosstest.global_runner = global_runner
    end

    describe '#bootstrap' do
      # Need an project that's already cloned
      let(:expected_project_dir) { 'samples/sdks/ruby' }

      it 'executes script/bootstrap' do
        expect(runner).to receive(:execute_task).with('bootstrap')
        project.bootstrap
      end
    end

    describe '#clone' do
      it 'does nothing if there is no clone option' do
        expect(runner).to_not receive(:execute)
        project.clone

        project.clone
      end

      context 'with git as a simple string' do
        it 'clones the repo specified by the string' do
          project.git = 'git@github.com/foo/bar'
          expect(global_runner).to receive(:execute).with("git clone git@github.com/foo/bar -b master #{expected_project_path}")
          project.clone
        end
      end

      context 'with git as a hash' do
        it 'clones the repo specified by the repo parameter' do
          project.git = { repo: 'git@github.com/foo/bar' }
          expect(global_runner).to receive(:execute).with("git clone git@github.com/foo/bar -b master #{expected_project_path}")
          project.clone
        end

        it 'clones the repo on the branch specified by the brach parameter' do
          project.git = { repo: 'git@github.com/foo/bar', branch: 'quuz' }
          expect(global_runner).to receive(:execute).with("git clone git@github.com/foo/bar -b quuz #{expected_project_path}")
          project.clone
        end

        it 'clones the repo to the location specified by the to parameter' do
          project.git = { repo: 'git@github.com/foo/bar', to: 'sdks/foo' }
          expect(global_runner).to receive(:execute).with('git clone git@github.com/foo/bar -b master sdks/foo')
          project.clone
        end
      end
    end

    describe '#build_scenario' do
      subject(:project) { Crosstest::Project.new name: 'some_project', basedir: File.absolute_path('spec/fixtures') }
      let(:scenario) { Fabricate(:scenario, name: 'factorial', vars: {}) }

      it 'builds a Scenario' do
        expect(scenario).to be_an_instance_of Crosstest::Scenario
      end

      it 'finds the source' do
        expected_file = Pathname.new 'spec/fixtures/factorial.py'
        expect(scenario.source_file).to eq(expected_file)
      end
    end
  end
end
