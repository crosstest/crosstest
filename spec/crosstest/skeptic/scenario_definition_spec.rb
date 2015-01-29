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
        it 'builds a scenario for a project' do
          expect(subject.build project).to be_an_instance_of Scenario
        end
      end
    end
  end
end
