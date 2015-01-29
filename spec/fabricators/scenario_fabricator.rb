# Fabricates test manifests (.crosstest_tests.yaml files)

SCENARIO_EVIDENCE_KEYS = Crosstest::Skeptic::Scenario::KEYS_TO_PERSIST
SCENARIO_DEFINITION_ATTRIBUTES = [:name, :suite, :properties]

Fabricator(:scenario, from: Crosstest::Skeptic::Scenario) do
  initialize_with do
    @transients = @_transient_attributes.dup
    data = to_hash
    scenario_definition_attrs = @transients.select { |k, v| v && SCENARIO_DEFINITION_ATTRIBUTES.include?(k) }
    data['scenario_definition'] = Fabricate(:scenario_definition, scenario_definition_attrs)
    @_klass.new(data).tap do | scenario |
      @transients.each do |key, value |
        scenario.send("#{key}=", value) if SCENARIO_EVIDENCE_KEYS.include? key
      end
    end
  end
  # source_file { 'spec/fixtures/factorial.py' }
  project
  [SCENARIO_EVIDENCE_KEYS, SCENARIO_DEFINITION_ATTRIBUTES].flatten.each do | key |
    transient key
  end
end

Fabricator(:scenario_definition, from: Crosstest::Skeptic::ScenarioDefinition) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  properties {}
end
