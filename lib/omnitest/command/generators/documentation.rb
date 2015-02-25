require 'json'
require 'omnitest/reporters'

module Omnitest
  module Command
    class Generate
      class Documentation < Thor::Group
        include Thor::Actions
        include Omnitest::Core::FileSystem
        include Omnitest::Psychic::Code2Doc::CodeHelper
        include Omnitest::Psychic::Code2Doc::SnippetHelper

        BUILTIN_GENERATORS = Dir["#{Omnitest::Reporters::GENERATORS_DIR}/*"].select { |f| File.directory? f }

        attr_reader :projects, :project, :project_name, :project_basedir

        class << self
          def generators
            BUILTIN_GENERATORS + Dir['tests/omnitest/generators/*'].select { |f| File.directory? f }
          end

          def generator_names
            generators.map { |d| File.basename d }
          end

          def generator_not_found(generator)
            s = "ERROR: No generator named #{generator}, available generators: "
            s << generator_names.join(', ')
          end

          def source_root
            Omnitest::RESOURCES_DIR
          end
        end

        argument :project_regexp, default: 'all'
        argument :scenario_regexp, default: 'all'
        class_option :source, default: 'doc-src/', desc: 'Source folder with documentation templates'
        class_option :destination, default: 'docs/', desc: 'Destination for generated documentation'
        class_option :template, desc: 'The name or location of a custom generator template'
        class_option :scope, desc: 'Whether the template should be applied once (global), per project, or per scenario',
                             enum: %w(global project scenario), default: 'global'
        class_option :failed, type: :boolean, desc: 'Only list tests that failed / passed'
        class_option :skipped, type: :boolean, desc: 'Only list tests that were skipped / executed'
        class_option :samples, type: :boolean, desc: 'Only list tests that have sample code / do not have sample code'
        class_option :travis, type: :boolean, desc: "Enable/disable delegation to travis-build, if it's available"
        def setup
          Omnitest.update_config!(options)
          Omnitest.setup
        end

        def set_source_and_destination
          unless options[:template] || File.exist?(options[:source])
            abort 'Either the --source directory must exist, or --template must be specified'
          end

          if options[:template]
            generator = self.class.generators.find { |d| File.basename(d) == options[:template] }
            abort self.class.generator_not_found(generator) if generator.nil?
            source_paths << generator
          else
            source_paths << Pathname(options[:source]).expand_path
          end

          self.destination_root = options[:destination]
        end

        def apply_template
          if options[:template]
            generator_script = "#{options[:template]}_template.rb"
            apply(generator_script)
          else
            case options[:scope]
            when 'global'
              @projects = Omnitest.filter_projects(project_regexp)
              process_directory
            when 'project'
              Omnitest.filter_projects(project_regexp).each do | project |
                bind_project_variables(project)
                process_directory
              end
            when 'scenario'
              Omnitest.scenarios(project_regexp, scenario_regexp).each do | scenario |
                bind_scenario_variables(scenario)
                process_directory
              end
            end
          end
        end

        private

        def scenario_output_snippet(project_regex, scenario_regex, opts = {})
          scenario = Omnitest.scenarios(project_regex, scenario_regex).first
          fail "Output is not available for #{scenario_name} because that scenario does not exist" unless scenario
          fail "Output is not available for #{scenario_name} because it has not been executed" unless scenario.result
          snippetize_output(scenario.result, opts)
        end

        def process_directory
          directory Pathname(options[:source]).expand_path, Pathname(options[:destination]).expand_path
        end

        def bind_project_variables(project)
          @project = project
          @project_name = project.name
          @project_basedir = project.basedir
        end

        def bind_scenario_variables(scenario)
          bind_project_variables(scenario.project)
          @scenario = scenario
          @scenario_name = scenario.name
          @scenario_slug = scenario.slug
        end
      end
    end
  end
end
