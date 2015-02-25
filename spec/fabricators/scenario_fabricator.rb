Fabricator(:scenario_definition, from: Omnitest::Skeptic::ScenarioDefinition) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  properties {}
end
