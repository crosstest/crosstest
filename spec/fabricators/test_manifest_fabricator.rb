# Fabricates test manifests (.crosstest.yaml files)

Fabricator(:manifest, from: Crosstest::Skeptic::TestManifest) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  transient suite_count: 3
  transient samples_per_suite: 3
  global_env do
    {
      VAR1: 1,
      VAR2: 2
    }
  end
  suites do |attr|
    suite_count = attr[:suite_count]
    if suite_count
      suites = attr[:suite_count].times.each_with_object({}) do |i, h|
        name = LANGUAGES[i] ||= "suite_#{i}"
        h[name] = Fabricate(:suite, name: name, sample_count: attr[:samples_per_suite])
      end
      suites
    else
      nil
    end
  end
end

Fabricator(:suite, from: Crosstest::Core::Mash) do
  initialize_with { @_klass.new to_hash } # Hash based initialization
  transient name: LANGUAGES[0]
  transient sample_count: 3
  samples do |attr|
    sample_count = attr[:sample_count]
    if sample_count
      attr[:sample_count].times.map do |i|
        SCENARIO_NAMES[i] ||= "sample_#{i}"
      end
    else
      nil
    end
  end
end
