require 'thor'

require 'crosstest'
require 'crosstest/command'
require 'crosstest/command/generate'

module Crosstest
  class CLI < Thor # rubocop:disable ClassLength
    # Common module to load and invoke a CLI-implementation agnostic command.
    module PerformCommand
      # Perform a scenario subcommand.
      #
      # @param task [String] action to take, usually corresponding to the
      #   subcommand name
      # @param command [String] command class to create and invoke]
      # @param args [Array] remainder arguments from processed ARGV
      #   (default: `nil`)
      # @param additional_options [Hash] additional configuration needed to
      #   set up the command class (default: `{}`)
      def perform(task, command, args = nil, additional_options = {})
        require "crosstest/command/#{command}"

        command_options = {
          action: task,
          help: -> { help(task) },
          test_dir: @test_dir,
          shell: shell
        }.merge(additional_options)

        str_const = Thor::Util.camel_case(command)
        klass = ::Crosstest::Command.const_get(str_const)
        klass.new(args, options, command_options).call
      end
    end

    include Logging
    include PerformCommand

    # The maximum number of concurrent instances that can run--which is a bit
    # high
    MAX_CONCURRENCY = 9999

    # Constructs a new instance.
    def initialize(*args)
      super
      $stdout.sync = true
    end

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
    method_option :manifest,
                  aliases: '-m',
                  desc: 'The Crosstest test manifest file location',
                  default: 'crosstest.yaml'
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
    method_option :manifest,
                  aliases: '-m',
                  desc: 'The Crosstest test manifest file location',
                  default: 'crosstest.yaml'
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
      clone: 'Change scenario state to cloned. ' \
                    'Clone the code sample from git',
      bootstrap: 'Change scenario state to bootstraped. ' \
                    'Running bootstrap scripts for the project',
      detect: 'Find sample code that matches a test scenario. ' \
                    'Attempts to locate a code sample with a filename that the test scenario name.',
      exec: 'Change instance state to executed. ' \
                    'Execute the code sample and capture the results.',
      verify: 'Change instance state to verified. ' \
                    'Assert that the captured results match the expectations for the scenario.',
      destroy: 'Change scenario state to destroyed. ' \
                   'Delete all information for one or more scenarios'
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
      method_option :manifest,
                    aliases: '-m',
                    desc: 'The Crosstest test manifest file location',
                    default: 'crosstest.yaml'
      method_option :test_dir,
                    aliases: '-t',
                    desc: 'The Crosstest test directory',
                    default: 'tests/crosstest'
      define_method(action) do |*args|
        update_config!
        action_options = options.dup
        perform(action, 'action', args, action_options)
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
    method_option :manifest,
                  aliases: '-m',
                  desc: 'The Crosstest test manifest file location',
                  default: 'crosstest.yaml'
    method_option :test_dir,
                  aliases: '-t',
                  desc: 'The Crosstest test directory',
                  default: 'tests/crosstest'
    def test(*args)
      update_config!
      action_options = options.dup
      perform('test', 'test', args, action_options)
    end

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
    method_option :manifest,
                  aliases: '-m',
                  desc: 'The Crosstest test manifest file location',
                  default: 'crosstest.yaml'
    def task(*args)
      update_config!
      action_options = options.dup
      perform('task', 'project_action', args, action_options)
    end

    desc 'version', "Print Crosstest's version information"
    def version
      puts "Crosstest version #{Crosstest::VERSION}"
    end
    map %w(-v --version) => :version

    desc 'generate', 'Generate reports, documentation, etc.'
    subcommand 'generate', Crosstest::Command::Generate

    private

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
end
