# Fabricates test manifests (.omnitest.yaml files)

Fabricator(:project, from: Omnitest::Project) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  language { LANGUAGES.sample }
  name do |attr|
    "my_#{attr[:language]}_project"
  end
  basedir do |attr|
    "sdks/#{attr[:name]}"
  end
end

Fabricator(:project_set, from: Omnitest::ProjectSet) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  projects do
    Fabricate(:project)
  end
end
