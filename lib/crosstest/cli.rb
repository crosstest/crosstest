require 'thor'

require 'crosstest'
require 'crosstest/command'
require 'crosstest/command/generate'

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
      desc 'task <task_name> [PROJECT|REGEXP|all]',
           'Run a task in one or more projects'
      long_desc <<-DESC
        Runs the task in all projects or the projects specified.
      DESC
      method_option :concurrency,
                    aliases: '-c',
                    type: :numeric,
                    lazy_default: MAX_CONCURRENCY,
                    desc: <<-DESC.gsub(/^\s+/, '').gsub(/\n/, ' ')
          Run the task concurrently. If a value is given, it will be used as the max number of threads.
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
      method_option :exec,
                    aliases: '-e',
                    type: :boolean,
                    desc: 'An arbitrary command to execute instead of a task'
      def task(*args)
        update_config!
        action_options = options.dup
        perform('task', 'task', args, action_options)
      end

      {
        clone: 'Change scenario state to cloned. ' \
                      'Clone the code sample from git',
        bootstrap: 'Change scenario state to bootstraped. ' \
                      'Running bootstrap scripts for the project'
      }.each do |action, short_desc|
        desc(
          "#{action} [PROJECT|REGEXP|all]",
          short_desc
        )
        long_desc <<-DESC
          Executes the task in one or more projects.
        DESC
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
        method_option :skeptic,
                      aliases: '-s',
                      desc: 'The Skeptic test manifest file',
                      default: 'skeptic.yaml'
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

      {
        detect: 'Find sample code that matches a test scenario. ' \
                      'Attempts to locate a code sample with a filename that the test scenario name.',
        exec: 'Change instance state to executed. ' \
                      'Execute the code sample and capture the results.',
        verify: 'Change instance state to verified. ' \
                      'Assert that the captured results match the expectations for the scenario.',
        clear: 'Clear stored results for the scenario. ' \
                     'Delete all stored results for one or more scenarios'
      }.each do |action, short_desc|
        desc(
          "#{action} [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]",
          short_desc
        )
        long_desc <<-DESC
          The scenario states are in order: cloned, bootstrapped, executed, verified.
          Change one or more scenarios from the current state to the #{action} state. Actions for all
          intermediate states will be executed.
        DESC
        method_option :concurrency,
                      aliases: '-c',
                      type: :numeric,
                      lazy_default: MAX_CONCURRENCY,
                      desc: <<-DESC.gsub(/^\s+/, '').gsub(/\n/, ' ')
            Run a #{action} against all matching instances concurrently. Only N
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
        define_method(action) do |*args|
          update_config!
          action_options = options.dup
          perform(action, 'scenario_action', args, action_options)
        end
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
