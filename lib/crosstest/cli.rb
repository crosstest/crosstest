require 'thor'

require 'crosstest'
require 'crosstest/command'
require 'crosstest/command/generate'
require 'crosstest/psychic/cli'
require 'crosstest/skeptic/cli'

module Crosstest
  module Command
    class Generate
      autoload :Dashboard, 'crosstest/command/generators/dashboard'
      autoload :Code2Doc, 'crosstest/command/generators/code2doc'
      autoload :Documentation, 'crosstest/command/generators/documentation'
    end
  end

  module CLI
    class BaseCLI < Crosstest::Core::CLI
      # The maximum number of concurrent instances that can run--which is a bit
      # high
      MAX_CONCURRENCY = 9999

      # Constructs a new instance.
      def initialize(*args)
        super
        $stdout.sync = true
      end

      protected

      # Convert a Thor Option object to a hash so we can copy options from
      # other commands.
      #
      # @param [Thor::Option] an option object
      # @return [Hash] the options as a hash
      # @api private
      def self.option_to_hash(option)
        [
          :banner, :default, :description, :enum, :name,
          :required, :type, :aliases, :group, :hide, :lazy_default
        ].each_with_object({}) do | option_type, options_hash |
          options_hash[option_type] = option.send(option_type)
        end
      end

      # Ensure the any failing commands exit non-zero.
      #
      # @return [true] you die always on failure
      # @api private
      def self.exit_on_failure?
        true
      end

      # @return [Logger] the common logger
      # @api private
      def logger
        Crosstest.logger
      end

      # Update and finalize options for logging, concurrency, and other concerns.
      #
      # @api private
      def update_config!
        Crosstest.update_config!(@options)
      end

      # If auto_init option is active, invoke the init generator.
      #
      # @api private
      def ensure_initialized
      end

      def duration(total)
        total = 0 if total.nil?
        minutes = (total / 60).to_i
        seconds = (total - (minutes * 60))
        format('(%dm%.2fs)', minutes, seconds)
      end
    end

    class CrosstaskCLI < BaseCLI
      desc 'clone [PROJECT|REGEXP|all]', 'Fetches the projects from version control'
      method_option :concurrency,
                    aliases: '-c',
                    type: :numeric,
                    lazy_default: MAX_CONCURRENCY,
                    desc: <<-DESC.gsub(/^\s+/, '').gsub(/\n/, ' ')
          Run the task against all matching instances concurrently. Only N
          instances will run at the same time if a number is given.
        DESC
      method_option :log_level,
                    aliases: '-l',
                    desc: 'Set the log level (debug, info, warn, error, fatal)'
      method_option :file,
                      aliases: '-f',
                      desc: 'The Crosstest project set file',
                      default: 'crosstest.yaml'
      def clone(*args)
        update_config!
        action_options = options.dup
        perform('clone', 'project_action', args, action_options)
      end

      Psychic::CLI.commands.each do | action, command |
        enhanced_banner = "#{action} [PROJECT|REGEXP|all]"
        desc enhanced_banner, command.description
        long_desc command.long_description
        method_option :file,
                      aliases: '-f',
                      desc: 'The Crosstest project set file',
                      default: 'crosstest.yaml'
        command.options.select do | name, option |
          method_option name, option_to_hash(option)
        end
        define_method(action) do |*args|
          update_config!
          action_options = options.dup
          perform(action, 'project_action', args, action_options)
        end
      end
    end

    class CrossdocCLI < BaseCLI
      register Command::Generate::Dashboard, 'dashboard', 'dashboard', 'Create a report dashboard'
      tasks['dashboard'].options = Command::Generate::Dashboard.class_options

      register Command::Generate::Code2Doc, 'code2doc', 'code2doc [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]',
               'Generates documenation from sample code for one or more scenarios'
      tasks['code2doc'].options = Command::Generate::Code2Doc.class_options

      register Command::Generate::Documentation, 'generate', 'generate', 'Generates documentation, reports or other files from templates'
      tasks['generate'].options = Command::Generate::Documentation.class_options
      tasks['generate'].long_description = <<-eos
      Generates documentation, reports or other files from templates. The templates may use Thor actions and Padrino helpers
      in order to inject data from Crosstest test runs, code samples, or other sources.

      Available templates: #{Command::Generate::Documentation.generator_names.join(', ')}
      You may also run it against a directory containing a template with the --source option.
      eos
    end

    class CrosstestCLI < CrosstaskCLI # rubocop:disable ClassLength
      def self.filter_options
        method_option :failed,
                      type: :boolean,
                      desc: 'Only list tests that failed / passed'
        method_option :skipped,
                      type: :boolean,
                      desc: 'Only list tests that were skipped / executed'
        method_option :samples,
                      type: :boolean,
                      desc: 'Only list tests that have sample code / do not have sample code'
      end

      Skeptic::CLI.commands.each do | action, command |
        enhanced_banner = "#{action} [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]"
        desc enhanced_banner, command.description
        long_desc command.long_description
        method_option :file,
                      aliases: '-f',
                      desc: 'The Crosstest project set file',
                      default: 'crosstest.yaml'
        command.options.select do | name, option |
          method_option name, option_to_hash(option)
        end
        define_method action do |*args|
          update_config!
          action_options = options.dup
          perform(action, 'scenario_action', args, action_options)
        end
      end

      desc 'list [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]', 'Lists one or more scenarios'
      method_option :log_level,
                    aliases: '-l',
                    desc: 'Set the log level (debug, info, warn, error, fatal)'
      method_option :format,
                    desc: 'List output format',
                    enum: %w(text markdown json yaml),
                    default: 'text'
      method_option :file,
                    aliases: '-f',
                    desc: 'The Crosstest project set file',
                    default: 'crosstest.yaml'
      method_option :skeptic,
                    aliases: '-s',
                    desc: 'The Skeptic test manifest file',
                    default: 'skeptic.yaml'
      method_option :test_dir,
                    aliases: '-t',
                    desc: 'The Crosstest test directory',
                    default: 'tests/crosstest'
      filter_options
      def list(*args)
        update_config!
        perform('list', 'list', args, options)
      end

      desc 'show [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]', 'Show detailed status for one or more scenarios'
      method_option :log_level,
                    aliases: '-l',
                    desc: 'Set the log level (debug, info, warn, error, fatal)'
      method_option :format,
                    desc: 'List output format',
                    enum: %w(text markdown json yaml),
                    default: 'text'
      method_option :file,
                    aliases: '-f',
                    desc: 'The Crosstest project set file',
                    default: 'crosstest.yaml'
      method_option :skeptic,
                    aliases: '-s',
                    desc: 'The Skeptic test manifest file',
                    default: 'skeptic.yaml'
      method_option :source,
                    desc: 'Display the source code for the sample'
      method_option :test_dir,
                    aliases: '-t',
                    desc: 'The Crosstest test directory',
                    default: 'tests/crosstest'
      filter_options
      def show(*args)
        update_config!
        perform('show', 'show', args, options)
      end

      desc 'test [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]',
           'Test (clone, bootstrap, exec, and verify) one or more scenarios'
      long_desc <<-DESC
        The scenario states are in order: cloned, bootstrapped, executed, verified.
        Test changes the state of one or more scenarios executes
        the actions for each state up to verify.
      DESC
      method_option :concurrency,
                    aliases: '-c',
                    type: :numeric,
                    lazy_default: MAX_CONCURRENCY,
                    desc: <<-DESC.gsub(/^\s+/, '').gsub(/\n/, ' ')
          Run a test against all matching instances concurrently. Only N
          instances will run at the same time if a number is given.
        DESC
      method_option :log_level,
                    aliases: '-l',
                    desc: 'Set the log level (debug, info, warn, error, fatal)'
      method_option :file,
                    aliases: '-f',
                    desc: 'The Crosstest project set file',
                    default: 'crosstest.yaml'
      method_option :skeptic,
                    aliases: '-s',
                    desc: 'The Skeptic test manifest file',
                    default: 'skeptic.yaml'
      method_option :test_dir,
                    aliases: '-t',
                    desc: 'The Crosstest test directory',
                    default: 'tests/crosstest'
      def test(*args)
        update_config!
        action_options = options.dup
        perform('test', 'test', args, action_options)
      end

      desc 'version', "Print Crosstest's version information"
      def version
        puts "Crosstest version #{Crosstest::VERSION}"
      end
      map %w(-v --version) => :version
    end
  end
end
