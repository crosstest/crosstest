require 'thread'
require 'English'

module Omnitest
  module Command
    class Base # rubocop:disable ClassLength
      include Core::DefaultLogger
      include Omnitest::Core::Logging
      include Omnitest::Core::FileSystem

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
        Omnitest.setup
      end

      def project_set_file
        @project_set_file ||= Omnitest.configuration.file
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
        projects = Omnitest.filter_projects(project_regexp, options)
        die "No projects matching regex `#{project_regexp}', known projects: #{Omnitest.projects.map(&:name)}" if projects.empty?
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
        scenarios = Omnitest.scenarios(project_regexp, scenario_regexp, options)
        die "No scenarios for regex `#{scenario_regexp}', try running `omnitest list'" if scenarios.empty?
        scenarios
      rescue RegexpError => e
        die 'Invalid Ruby regular expression, ' \
          'you may need to single quote the argument. ' \
          "Please try again or consult http://rubular.com/ (#{e.message})"
      end
    end
  end
end
