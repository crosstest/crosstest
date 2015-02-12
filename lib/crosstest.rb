require 'crosstest/version'
require 'crosstest/core'
require 'crosstest/psychic'
require 'crosstest/skeptic'
require 'crosstest/run_action'
require 'crosstest/project'
require 'crosstest/workflow'
require 'crosstest/project_set'
require 'crosstest/project_logger'
require 'crosstest/configuration'
require 'crosstest/documentation_generator'

module Crosstest
  include Crosstest::Core::Logger
  include Crosstest::Core::Logging

  # File extensions that Crosstest can automatically detect/execute
  SUPPORTED_EXTENSIONS = %w(py rb js)

  module Delegators
    # @api private
    # @!macro delegate_to_skeptic
    #   @method $1()
    def delegate_to_skeptic_class(meth)
      define_method(meth) { |*args, &block| Skeptic.public_send(meth, *args, &block) }
    end

    # @api private
    # @!macro delegate_to_psychic
    #   @method $1()
    def delegate_to_psychic_class(meth)
      define_method(meth) { |*args, &block| Psychic.public_send(meth, *args, &block) }
    end

    # @api private
    # @!macro delegate_to_psychic
    #   @method $1()
    def delegate_to_psychic_instance(meth)
      define_method(meth) { |*args, &block| psychic.public_send(meth, *args, &block) }
    end

    # @api private
    # @!macro delegate_to_projects
    #   @method $1()
    def delegate_to_projects(meth)
      define_method(meth) do |*args, &block|
        project_regex = args.shift
        run_action(filter_projects(project_regex), meth, configuration.concurrency, *args, &block)
      end
    end

    # @api private
    # @!macro delegate_to_scenarios
    #   @method $1()
    def delegate_to_scenarios(meth)
      define_method(meth) do |*args, &block|
        project_regex = args.shift
        scenario_regex = args.shift
        scenarios(project_regex, scenario_regex).map { |s| s.public_send(meth, *args, &block) }
      end
    end
  end

  class << self
    include Core::Configurable
    include RunAction
    extend Delegators

    DEFAULT_PROJECT_SET_FILE = 'crosstest.yaml'
    DEFAULT_TEST_MANIFEST_FILE = 'skeptic.yaml'

    # @return [Logger] the common Crosstest logger
    attr_accessor :logger

    attr_accessor :psychic

    attr_accessor :wants_to_quit

    def new_logger(project) # (test, project, index)
      name = project.name # instance_name(test, project)
      index = Crosstest.projects.index(project) || 0
      ProjectLogger.new(
        stdout: STDOUT,
        color: Core::Color::COLORS[index % Core::Color::COLORS.size].to_sym,
        logdev: File.join(Crosstest.configuration.log_root, "#{name}.log"),
        level: Crosstest::Core::Util.to_logger_level(Crosstest.configuration.log_level),
        progname: name
      )
    end

    def basedir
      @basedir ||= psychic.basedir
    end

    # @private
    def trap_interrupt
      trap('INT') do
        exit!(1) if Crosstest.wants_to_quit
        Crosstest.wants_to_quit = true
        STDERR.puts "\nInterrupt detected... Interrupt again to force quit."
      end
    end

    def update_config!(options)
      trap_interrupt
      @logger = Crosstest.default_file_logger
      project_set_file = options.file || DEFAULT_PROJECT_SET_FILE
      @basedir = File.dirname project_set_file
      skeptic_file = options.skeptic || DEFAULT_TEST_MANIFEST_FILE

      Crosstest.configure do | config |
        config.concurrency = options.concurrency
        config.log_level = options.log_level || :info
        config.project_set = project_set_file
        config.skeptic.manifest_file = skeptic_file
        config.travis = options.travis if options.respond_to? :travis
      end
      @test_dir = options.test_dir || File.expand_path('tests/crosstest/', @basedir)
    end

    delegate_to_skeptic_class :validate

    delegate_to_projects :task

    delegate_to_projects :workflow

    delegate_to_projects :clone

    delegate_to_projects :bootstrap

    delegate_to_scenarios :test

    delegate_to_scenarios :clear

    delegate_to_scenarios :code2doc

    Skeptic::Scenario::FSM::TRANSITIONS.each do | transition |
      delegate_to_scenarios transition
    end

    def setup
      # This autoload should probably be in Skeptic's initializer...
      autoload_crosstest_files(@test_dir) unless @test_dir.nil? || !File.directory?(@test_dir)
    end

    def scenarios(project_regexp = 'all', scenario_regexp = 'all', options = {})
      filtered_projects = filter_projects(project_regexp, options)
      filtered_scenarios = filtered_projects.map(&:skeptic).flat_map do | skeptic |
        skeptic.scenarios scenario_regexp, options
      end

      fail UserError, "No scenarios for regex `#{scenario_regexp}', try running `crosstest list'" if filtered_scenarios.empty?
      filtered_scenarios
    end

    def filter_projects(regexp = 'all', _options = {})
      return Crosstest.projects if regexp.nil? || regexp == 'all'

      filtered_projects = Crosstest.projects.find { |s| s.name == regexp }
      return [filtered_projects] if filtered_projects

      filtered_projects ||= Crosstest.projects.select { |s| s.name =~ /#{regexp}/i }
      fail UserError, "No projects matching regex `#{regexp}', known projects: #{Crosstest.projects.map(&:name)}" if filtered_projects.empty?

      filtered_projects
    end

    # Returns a default file logger which emits on standard output and to a
    # log file.
    #
    # @return [Logger] a logger
    def default_file_logger
      logfile = File.expand_path(File.join('.crosstest', 'logs', 'crosstest.log'))
      ProjectLogger.new(stdout: $stdout, logdev: logfile, level: Core::Util.to_logger_level(configuration.log_level))
    end

    # The {Crosstest::TestManifest} that describes the test scenarios known to Crosstest.
    def manifest
      configuration.skeptic.manifest
    end

    # The set of {Crosstest::Project}s registered with Crosstest.
    def projects
      configuration.project_set.projects.values
    end

    # @api private
    def psychic
      @psychic ||= Crosstest::Psychic.new(cwd: Crosstest.basedir, logger: logger, travis: Crosstest.configuration.travis)
    end

    # Returns whether or not standard output is associated with a terminal
    # device (tty).
    #
    # @return [true,false] is there a tty?
    def tty?
      $stdout.tty?
    end

    protected

    def autoload_crosstest_files(dir)
      $LOAD_PATH.unshift dir
      Dir["#{dir}/**/*.rb"].each do | file_to_require |
        # TODO: Need a better way to skip generators or only load validators
        next if file_to_require.match %r{generators/.*/files/}
        require Crosstest::Core::FileSystem.relativize(file_to_require, dir).to_s.gsub('.rb', '')
      end
    end
  end
end
