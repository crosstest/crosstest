require 'json'
require 'crosstest/reporters'

module Crosstest
  module Command
    class Generate
      class Documentation < Thor::Group
        include Thor::Actions
        include Crosstest::Core::FileSystem
        include Crosstest::Core::FileSystem
        include Crosstest::Code2Doc::Helpers::CodeHelper

        BUILTIN_GENERATORS = Dir["#{Crosstest::Reporters::GENERATORS_DIR}/*"].select { |f| File.directory? f }

        class << self
          def generators
            BUILTIN_GENERATORS + Dir['tests/crosstest/generators/*'].select { |f| File.directory? f }
          end

          def generator_names
            generators.map { |d| File.basename d }
          end

          def generator_not_found(generator)
            s = "ERROR: No generator named #{generator}, available generators: "
            s << generator_names.join(', ')
          end
        end

        argument :regexp, default: 'all'
        class_option :template, default: 'summary', desc: 'The generator template name or directory'
        class_option :destination, default: 'docs/', desc: 'Destination for generated documentation'
        class_option :failed, type: :boolean, desc: 'Only list tests that failed / passed'
        class_option :skipped, type: :boolean, desc: 'Only list tests that were skipped / executed'
        class_option :samples, type: :boolean, desc: 'Only list tests that have sample code / do not have sample code'

        def setup
          Crosstest.setup(options)
        end

        def select_scenarios
          @scenarios = Crosstest.filter_scenarios(regexp, options)
        end

        def set_source_and_destination
          generator = self.class.generators.find { |d| File.basename(d) == options[:template] }
          abort self.class.generator_not_found(generator) if generator.nil?
          source_paths << generator

          self.destination_root = options[:destination]
        end

        def apply_template
          generator_script = "#{options[:template]}_template.rb"
          apply(generator_script)
        end
      end
    end
  end
end
