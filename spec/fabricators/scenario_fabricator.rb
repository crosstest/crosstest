Fabricator(:scenario_definition, from: Crosstest::Skeptic::ScenarioDefinition) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  properties {}
end
