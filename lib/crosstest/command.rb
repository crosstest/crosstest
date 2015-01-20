require 'thread'
require 'English'

module Crosstest
  module Command
    class Base # rubocop:disable ClassLength
      include Core::DefaultLogger
      include Crosstest::Core::Logging
      include Crosstest::Core::FileSystem

      # Contstructs a new Command object.
      #
      # @param cmd_args [Array] remainder of the arguments from processed ARGV
      # @param cmd_options [Hash] hash of Thor options
      # @param options [Hash] configuration options
      # @option options [String] :action action to take, usually corresponding
      #   to the subcommand name (default: `nil`)
      # @option options [proc] :help a callable that displays help for the
      #   command
      # @option options [Config] :test_dir a Config object (default: `nil`)
      # @option options [Loader] :loader a Loader object (default: `nil`)
      # @option options [String] :shell a Thor shell object
      def initialize(cmd_args, cmd_options, options = {})
        @args = cmd_args
        @options = cmd_options
        @action = options.fetch(:action, nil)
        @help = options.fetch(:help, -> { 'No help provided' })
        @project_set_file = options.fetch('file', nil)
        @loader = options.fetch(:loader, nil)
        @shell = options.fetch(:shell)
        @queue = Queue.new
      end

      private

      # @return [Array] remainder of the arguments from processed ARGV
      # @api private
      attr_reader :args

      # @return [Hash] hash of Thor options
      # @api private
      attr_reader :options

      # @return [proc] a callable that displays help for the command
      # @api private
      attr_reader :help

      # @return [Thor::Shell] a Thor shell object
      # @api private
      attr_reader :shell

      # @return [String] the action to perform
      # @api private
      attr_reader :action

      def setup
        Crosstest.setup(options, @project_set_file)
      end

      def project_set_file
        @project_set_file ||= Crosstest.configuration.file
        @project_set_file
      end

      # Emit an error message, display contextual help and then exit with a
      # non-zero exit code.
      #
      # **Note** This method calls exit and will not return.
      #
      # @param msg [String] error message
      # @api private
      def die(msg)
        logger.error "\n#{msg}\n\n"
        help.call
        exit 1
      end

      # Return an array on scenarios whos name matches the regular expression,
      # the full instance name, or  the `"all"` literal.
      #
      # @param arg [String] an instance name, a regular expression, the literal
      #   `"all"`, or `nil`
      # @return [Array<Instance>] an array of scenarios
      # @api private
      def parse_subcommand(project_regexp = 'all', scenario_regexp = 'all', options = {})
        projects = Crosstest.filter_projects(project_regexp, options)
        die "No projects matching regex `#{project_regexp}', known projects: #{Crosstest.projects.map(&:name)}" if projects.empty?
        scenarios = Crosstest.filter_scenarios(scenario_regexp, options)
        die "No scenarios for regex `#{scenario_regexp}', try running `crosstest list'" if scenarios.empty?
        scenarios.keep_if do |s|
          projects.include? s.project
        end
      rescue RegexpError => e
        die 'Invalid Ruby regular expression, ' \
          'you may need to single quote the argument. ' \
          "Please try again or consult http://rubular.com/ (#{e.message})"
      end
    end

    # Common module to execute a Crosstest action such as create, converge, etc.
    module RunAction
      # Run an instance action (create, converge, setup, verify, destroy) on
      # a collection of scenarios. The instance actions will take place in a
      # seperate thread of execution which may or may not be running
      # concurrently.
      #
      # @param action [String] action to perform
      # @param scenarios [Array<Instance>] an array of scenarios
      def run_action(_action, scenarios, *args)
        @args.concat args
        concurrency = 1
        if options[:concurrency]
          concurrency = options[:concurrency] || scenarios.size
          concurrency = scenarios.size if concurrency > scenarios.size
        end

        scenarios.each { |i| @queue << i }
        concurrency.times { @queue << nil }

        errors = []

        threads = concurrency.times.map { |i| spawn(i) }
        threads.map do |t|
          begin
            t.join
          rescue Interrupt
            raise
          rescue Crosstest::ActionFailed => e
            errors << e
            # logger.error(e.message) # Should already be logged
          rescue => e # Crosstest::ExecutionError, Crosstest::ScenarioFailure
            test_env_num = t[:test_env_number]
            logger.warn("Thread for test_env_number: #{test_env_num} died because:")
            logger.error(Crosstest::Error.formatted_trace(e).join("\n"))
            logger.warn('Spawning a replacement...')
            # respawn thread
            t.kill
            threads.delete(t)
            threads.push(spawn(test_env_num))
          end
        end while threads.any?(&:alive?)

        unless errors.empty?
          logger.error
          logger.error('Error summary:')
          errors.each do | error |
            logger.error(error)
          end
          exit 1
        end
      end

      private

      def spawn(i)
        Thread.new(i) do |test_env_number|
          Thread.current[:test_env_number] = test_env_number
          while (instance = @queue.pop)
            begin
              instance.public_send(action, *args)
            rescue Crosstest::ExecutionError, Crosstest::ScenarioFailure => e
              logger.error(e)
            rescue => e
              logger.warn('An unexpected error occurred')
              logger.error(e)
              raise
            end
          end
        end
      end
    end
  end
end
