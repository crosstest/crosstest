# Fabricates test manifests (.crosstest_tests.yml files)

Fabricator(:scenario, from: Crosstest::Scenario) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  name { SCENARIO_NAMES.sample }
  suite { LANGUAGES.sample }
  source_file { 'spec/fixtures/factorial.py' }
  basedir { 'spec/fixtures' }
  project
end
