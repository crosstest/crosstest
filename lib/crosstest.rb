require 'crosstest/version'
require 'crosstest/core'
require 'crosstest/psychic'
require 'crosstest/skeptic'
require 'crosstest/project'
require 'crosstest/project_set'
require 'crosstest/project_logger'
require 'crosstest/error'
require 'crosstest/scenario'
require 'crosstest/scenarios'
require 'crosstest/configuration'
require 'crosstest/documentation_generator'

module Crosstest
  include Crosstest::Core::Logger
  include Crosstest::Core::Logging

  # File extensions that Crosstest can automatically detect/execute
  SUPPORTED_EXTENSIONS = %w(py rb js)

  class << self
    DEFAULT_PROJECT_SET_FILE = 'crosstest.yaml'
    DEFAULT_TEST_MANIFEST_FILE = 'skeptic.yaml'

    # @return [Mutex] a common mutex for global coordination
    attr_accessor :mutex

    # @return [Logger] the common Crosstest logger
    attr_accessor :logger

    attr_accessor :global_runner

    attr_accessor :wants_to_quit

    def logger
      @logger ||= Crosstest.default_file_logger
    end

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
      @basedir ||= Dir.pwd
    end

    # @private
    def trap_interrupt
      trap('INT') do
        exit!(1) if Crosstest.wants_to_quit
        Crosstest.wants_to_quit = true
        STDERR.puts "\nInterrupt detected... Interrupt again to force quit."
      end
    end

    def setup(options, project_set_file = DEFAULT_PROJECT_SET_FILE, test_manifest_file = DEFAULT_TEST_MANIFEST_FILE)
      trap_interrupt

      # logger.debug "Loading project set file: #{project_set_file}"
      @basedir = File.dirname project_set_file
      Crosstest.configuration.project_set = project_set_file

      # logger.debug "Loading skeptic file: #{test_manifest_file}"
      @basedir = File.dirname test_manifest_file
      Crosstest.configuration.manifest = test_manifest_file

      manifest.build_scenarios(configuration.project_set.projects)

      test_dir = options[:test_dir] || File.expand_path('tests/crosstest/', Dir.pwd)
      autoload_crosstest_files(test_dir) unless test_dir.nil? || !File.directory?(test_dir)
      manifest
    end

    def select_scenarios(regexp)
      regexp ||= 'all'
      scenarios = manifest.scenarios.values
      if regexp == 'all'
        return scenarios
      else
        scenarios = scenarios.find { |c| c.full_name == regexp } ||
                    scenarios.select { |c| c.full_name =~ /#{regexp}/i }
      end

      if scenarios.is_a? Array
        scenarios
      else
        [scenarios]
      end
    end

    def filter_scenarios(regexp, options = {})
      select_scenarios(regexp).tap do |scenarios|
        scenarios.keep_if { |scenario| scenario.failed? == options[:failed] } unless options[:failed].nil?
        scenarios.keep_if { |scenario| scenario.skipped? == options[:skipped] } unless options[:skipped].nil?
        scenarios.keep_if { |scenario| scenario.sample? == options[:samples] } unless options[:samples].nil?
      end
    end

    def filter_projects(regexp, _options = {})
      regexp ||= 'all'
      projects = if regexp == 'all'
                   Crosstest.projects
                 else
                   Crosstest.projects.find { |s| s.name == regexp } ||
                   Crosstest.projects.select { |s| s.name =~ /#{regexp}/i }
                 end
      if projects.is_a? Array
        projects
      else
        [projects]
      end
    end

    # Returns a default file logger which emits on standard output and to a
    # log file.
    #
    # @return [Logger] a logger
    def default_file_logger
      logfile = File.expand_path(File.join('.crosstest', 'logs', 'crosstest.log'))
      ProjectLogger.new(stdout: $stdout, logdev: logfile, level: env_log)
    end

    # Determine the default log level from an environment variable, if it is
    # set.
    #
    # @return [Integer,nil] a log level or nil if not set
    # @api private
    def env_log
      level = ENV['CROSSTEST_LOG'] && ENV['CROSSTEST_LOG'].downcase.to_sym
      level = Util.to_logger_level(level) unless level.nil?
      level
    end

    # Default log level verbosity
    DEFAULT_LOG_LEVEL = :info

    def reset
      @configuration = nil
      Crosstest::Skeptic::ValidatorRegistry.clear
    end

    # The {Crosstest::TestManifest} that describes the test scenarios known to Crosstest.
    def manifest
      configuration.manifest
    end

    # The set of {Crosstest::Project}s registered with Crosstest.
    def projects
      configuration.project_set.projects.values
    end

    # Registers a {Crosstest::Skeptic::Validator} that will be used during test
    # execution on matching {Crosstest::Scenario}s.
    def validate(desc, scope = { suite: //, scenario: // }, &block)
      fail ArgumentError 'You must pass block' unless block_given?
      validator = Crosstest::Skeptic::Validator.new(desc, scope, &block)

      Crosstest::Skeptic::ValidatorRegistry.register validator
      validator
    end

    # @api private
    def global_runner
      @global_runner ||= Crosstest::Psychic.new(cwd: Crosstest.basedir, logger: logger)
    end

    # @see Crosstest::Configuration
    def configuration
      fail "configuration doesn't take a block, use configure" if block_given?
      @configuration ||= Configuration.new
    end

    # @see Crosstest::Configuration
    def configure
      yield(configuration)
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

Crosstest.mutex = Mutex.new
