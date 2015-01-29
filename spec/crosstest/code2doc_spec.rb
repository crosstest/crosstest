require 'spec_helper'

module Crosstest
  describe Code2Doc do
    describe '.file_snippet' do
      let(:file) { 'samples/crosstest_simple.yaml' }
      let(:file_content) { File.read file }

      it 'returns the file content as a code block' do
        generated_content = Crosstest::Code2Doc.file_snippet('samples/crosstest_simple.yaml')
        expect(generated_content).to eq("```yaml\n#{file_content}```")
      end

      it 'can have the language overriden' do
        generated_content = Crosstest::Code2Doc.file_snippet('samples/crosstest_simple.yaml', language: 'rb')
        expect(generated_content).to eq("```rb\n#{file_content}```")
      end

      it 'can return the snippet after a pattern' do
        generated_content = Crosstest::Code2Doc.file_snippet('samples/crosstest_simple.yaml', after: 'python:')
        expect(generated_content).to match("```yaml\n      basedir: 'projects/python_samples'\n```")
      end

      it 'can return the snippet before a pattern' do
        generated_content = Crosstest::Code2Doc.file_snippet('samples/crosstest_simple.yaml', before: 'ruby:')
        expect(generated_content).to match("```yaml\n---\n  projects:\n```")
      end
    end

    describe '.file_snippet' do
      let(:scenario) do
        project = Crosstest::Project.new name: 'some_sdk', basedir: 'spec/fixtures'
        scenario = Fabricate(:scenario_definition, name: 'factorial', vars: {}).build(project)
        scenario.test
        scenario
      end
      let(:scenario_name) { 'my_scenario' }

      before(:each) do
        allow(Crosstest).to receive(:scenario).with(scenario_name).and_return(scenario)
        scenario.test
        Crosstest.manifest.scenarios[scenario.slug] = scenario
      end

      it 'returns the output from the scenario' do
        output = Crosstest::Code2Doc.scenario_output_snippet(scenario_name)
        expect(output).to eq("```\n$ ./factorial.py\n#{scenario.result.stdout}```")
      end

      it 'can omit the command' do
        output = Crosstest::Code2Doc.scenario_output_snippet(scenario_name, include_command: false)
        expect(output).to eq("```\n#{scenario.result.stdout}```")
      end
    end
  end
end
