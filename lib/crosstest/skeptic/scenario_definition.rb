module Crosstest
  module Skeptic
    class ScenarioDefinition < Crosstest::Core::Dash # rubocop:disable ClassLength
      required_field :name, String
      required_field :suite, String, required: true
      field :properties, Hash[String => PropertyDefinition]

      def build(project)
        scenario_data = to_hash.dup
        scenario_data.delete(:properties)
        scenario_data[:basedir] ||= project.basedir
        scenario_data[:project] ||= project
        scenario_data[:suite] ||= ''
        begin
          scenario_data[:source_file] ||= Core::FileSystem.find_file project.basedir, scenario_data[:name]
          scenario_data[:source_file] = Core::FileSystem.relativize(scenario_data[:source_file], scenario_data[:basedir])
        rescue Errno::ENOENT
          scenario_data[:source_file] = nil
        end
        Scenario.new(scenario_data)
      end
    end
  end
end
