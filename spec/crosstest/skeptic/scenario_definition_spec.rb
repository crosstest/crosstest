require 'spec_helper'

module Crosstest
  module Skeptic
    RSpec.describe ScenarioDefinition do
      let(:project) { Fabricate(:project) }
      let(:definition) do
        {
          name: 'My test scenario',
          suite: 'My API',
          properties: {
            foo: {
              required: true,
              default: 'bar'
            }
          }
        }
      end

      subject { described_class.new(definition) }

      describe '#build' do
        let(:scenario) { subject.build project }

        it 'builds a Scenario for the Project' do
          expect(scenario).to be_an_instance_of Scenario
          expect(scenario.project).to eq(project)
        end

        xit 'finds the source' do
          expected_file = Pathname.new 'spec/fixtures/factorial.py'
          expect(scenario.source_file).to eq(expected_file)
        end
      end
    end
  end
end
