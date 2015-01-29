# Fabricates test manifests (.crosstest_tests.yaml files)

Fabricator(:scenario, from: Crosstest::Skeptic::Scenario) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  source_file { 'spec/fixtures/factorial.py' }
  basedir { 'spec/fixtures' }
  project
end

Fabricator(:scenario_definition, from: Crosstest::Skeptic::ScenarioDefinition) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  properties { }
end
