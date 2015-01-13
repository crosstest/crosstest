require 'spec_helper'
require 'crosstest/cli'

module Crosstest
  describe CLI do
    let(:kernel) { double(:kernel) }
    subject { ThorSpy.on(described_class, kernel) }
    describe 'bootstrap' do
      context 'with no args' do
        it 'calls bootstrap on each project' do
          expect(kernel).to receive(:exit).with(0)
          # TODO: Any way to test each project is called? We can't use
          # `Crosstest.projects` because it will be reloaded.
          subject.bootstrap
        end
      end

      context 'with an existing project' do
        xit 'calls bootstrap on the project' do
          # expect(@project).to receive(:bootstrap)
          expect(kernel).to receive(:exit).with(0)
          expect(subject.stderr.string).to eq('')
          subject.bootstrap('test')
        end
      end

      context 'with an non-existant project' do
        it 'fails' do
          expect(kernel).to receive(:exit).with(1)
          subject.bootstrap('missing')
          expect(subject.stdout.string).to include('No projects matching regex `missing\'')
        end
      end
    end
  end
end
