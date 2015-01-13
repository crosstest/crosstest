require 'json'
require 'crosstest/reporters'

module Crosstest
  module Command
    class Generate
      class Code2Doc < Thor::Group
        include Crosstest::DefaultLogger
        include Crosstest::Logging
        include Thor::Actions
        include Crosstest::Util::FileSystem

        class_option :log_level,
                     aliases: '-l',
                     desc: 'Set the log level (debug, info, warn, error, fatal)'
        class_option :manifest,
                     aliases: '-m',
                     desc: 'The Crosstest test manifest file location',
                     default: 'crosstest.yaml'
        class_option :solo,
                     desc: 'Enable solo mode - Crosstest will auto-configure a single project and its scenarios'
        # , default: 'crosstest.yaml'
        class_option :solo_glob,
                     desc: 'The globbing pattern to find code samples in solo mode'
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

        def setup
          # HACK: Need to make Command setup/parse_subcommand easily re-usable in Thor::Group actions
          command_options = {
            shell: shell
          }.merge(options)
          command = Crosstest::Command::Base.new(args, options, command_options)
          command.send(:setup)
          @scenarios = command.send(:parse_subcommand, args.shift, args.shift)
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
            rescue Crosstest::Documentation::CommentStyles::UnknownStyleError
              warn "Could not generated documentation for #{source_file}, because the language couldn't be detected."
            end
          end
        end
      end
    end
  end
end
