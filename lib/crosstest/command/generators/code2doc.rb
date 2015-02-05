require 'json'
require 'crosstest/reporters'

module Crosstest
  module Command
    class Generate
      class Code2Doc < Thor::Group
        include Core::DefaultLogger
        include Crosstest::Core::Logging
        include Thor::Actions
        include Crosstest::Core::FileSystem

        class_option :log_level,
                     aliases: '-l',
                     desc: 'Set the log level (debug, info, warn, error, fatal)'
        class_option :file,
                     aliases: '-f',
                     desc: 'The Crosstest project set file',
                     default: 'crosstest.yaml'
        class_option :skeptic,
                     aliases: '-s',
                     desc: 'The Skeptic test manifest file',
                     default: 'skeptic.yaml'
        class_option :format,
                     aliases: '-f',
                     enum: %w(md rst),
                     default: 'md',
                     desc: 'Target documentation format'
        class_option :target_dir,
                     aliases: '-d',
                     default: 'docs/',
                     desc: 'The target directory where documentation for generated documentation.'

        class_option :destination, default: 'docs/'

        argument :project_regexp, default: 'all'
        argument :scenario_regexp, default: 'all'

        def setup
          Crosstest.update_config!(options)
          Crosstest.setup
          @scenarios = Crosstest.scenarios(project_regexp, scenario_regexp, options)
          abort "No scenarios for regex `#{scenario_regexp}', try running `crosstest list'" if @scenarios.empty?
        end

        def set_destination_root
          self.destination_root = options[:destination]
        end

        def code2doc
          @scenarios.each do | scenario |
            source_file = scenario.source_file
            if source_file.nil?
              warn "No code sample available for #{scenario.slug}, no documentation will be generated."
              next
            end

            target_file_name = scenario.slug + ".#{options[:format]}"

            begin
              doc = Crosstest::DocumentationGenerator.new.code2doc(scenario.absolute_source_file)
              create_file(target_file_name, doc)
            rescue Crosstest::Code2Doc::CommentStyles::UnknownStyleError
              warn "Could not generated documentation for #{source_file}, because the language couldn't be detected."
            end
          end
        end
      end
    end
  end
end
