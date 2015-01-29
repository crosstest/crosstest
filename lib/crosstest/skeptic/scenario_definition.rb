module Crosstest
  module Skeptic
    class ScenarioDefinition < Crosstest::Core::Dash # rubocop:disable ClassLength
      required_field :name, String
      required_field :suite, String, required: true
      field :properties, Hash[String => PropertyDefinition]
      # TODO: Vars will be replaced by properties
      field :vars, Skeptic::TestManifest::Environment, default: {}
      attr_reader :full_name

      def initialize(data)
        super
        @full_name = [suite, name].join(' :: ').freeze
      end

      def build(project)
        source_file = begin
          file = Core::FileSystem.find_file project.basedir, name
          Core::FileSystem.relativize(file, project.basedir)
        rescue Errno::ENOENT
          nil
        end
        Scenario.new(project: project, scenario_definition: self, vars: build_vars, source_file: source_file)
      end

      private

      def build_vars
        # TODO: Build vars from properties
        global_vars = begin
          Crosstest.manifest[:global_env].dup
        rescue
          {}
        end
        global_vars.merge(vars.dup)
      end
    end
  end
end
