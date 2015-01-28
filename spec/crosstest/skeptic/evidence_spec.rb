require 'spec_helper'

module Crosstest
  module Skeptic
    RSpec.describe Evidence do
      let(:file) { Pathname('evidence.pstore').expand_path(current_dir) }
      subject { described_class.new(file) }

      let(:sample_data) do
        {
          last_attempted_action: 'foo',
          last_completed_action: 'bar',
          result: {
            execution_result: {
              command: 'echo foo',
              stdout: File.read(__FILE__),
              stderr: File.read(__FILE__),
              exitstatus: 0
            },
            source_file: 'foo/bar.rb',
            data: {},
            validations: nil
          },
          spy_data: {
            complex: {
              nested: %w(object that can be stored)
            }
          },
          error: ::StandardError.new,
          vars: {
            a: 'b',
            c: 'd',
            e: 'f'
          },
          duration: 123.5
        }
      end

      describe '#save' do
        it 'creates a file' do
          expect { subject.save }.to change { file.exist? }.from(false).to(true)
        end

        it 'persists data that can be reloaded' do
          sample_data.each do |key, value|
            subject[key] = value
          end
          subject.save

          reloaded_evidence = described_class.load(file)
          original_data = subject.to_hash
          reloaded_data = reloaded_evidence.to_hash
          expect(reloaded_data).to eq(original_data)
        end
      end
    end
  end
end
