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
      def initialize(action, cmd_args, cmd_options, options = {})
        @action = action
        @args = cmd_args
        @options = cmd_options
        @help = options.fetch(:help, -> { 'No help provided' })
        @project_set_file = options.fetch('file', nil)
        @skeptic_file = options.fetch('skeptic', nil)
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
        Crosstest.setup
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

      def select_projects(project_regexp = 'all', options = {})
        projects = Crosstest.filter_projects(project_regexp, options)
        die "No projects matching regex `#{project_regexp}', known projects: #{Crosstest.projects.map(&:name)}" if projects.empty?
        projects
      end

      # Return an array on scenarios whos name matches the regular expression,
      # the full instance name, or  the `"all"` literal.
      #
      # @param arg [String] an instance name, a regular expression, the literal
      #   `"all"`, or `nil`
      # @return [Array<Instance>] an array of scenarios
      # @api private
      def parse_subcommand(project_regexp = 'all', scenario_regexp = 'all', options = {})
        scenarios = Crosstest.scenarios(project_regexp, scenario_regexp, options)
        die "No scenarios for regex `#{scenario_regexp}', try running `crosstest list'" if scenarios.empty?
        scenarios
      rescue RegexpError => e
        die 'Invalid Ruby regular expression, ' \
          'you may need to single quote the argument. ' \
          "Please try again or consult http://rubular.com/ (#{e.message})"
      end
    end

    require 'celluloid'
    # Common module to execute a Crosstest action such as create, converge, etc.
    module RunAction
      class Worker
        include Celluloid

        def work(item, action, test_env_number, *args)
          item.vars['TEST_ENV_NUMBER'] = test_env_number if item.respond_to? :vars
          item.public_send(action, *args)
        rescue Crosstest::TransientFailure
          # Celluloid supervisor should be restarting actors after errors, but
          # it seems to die, so stop the error from propagating...
          nil
        end
      end

      # Run an action on each member of the collection. The collection could
      # be Projects (e.g. clone, bootstrap) or Scenarios (e.g. test, clean).
      # The instance actions will take place in a seperate thread of execution
      # which may or may not be running concurrently.
      #
      # @param collection [Array] an array of objections on which to perform the action
      def run_action(collection, action, *args)
        @args.concat args
        concurrency = 1
        if options[:concurrency]
          concurrency = options[:concurrency] || collection.size
          concurrency = collection.size if concurrency > collection.size
        end

        if concurrency > 1
          Celluloid::Actor[:crosstest_worker] = Worker.pool(size: concurrency)
        else
          Worker.supervise_as :crosstest_worker
        end

        futures = collection.each_with_index.map do |item, index|
          actor = Celluloid::Actor[:crosstest_worker]
          actor.work(item, action, index, *args)
        end
      end
    end
  end
end
