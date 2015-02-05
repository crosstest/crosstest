require 'crosstest/version'
require 'crosstest/core'
require 'crosstest/psychic'
require 'crosstest/skeptic'
require 'crosstest/code2doc'
require 'crosstest/project'
require 'crosstest/project_set'
require 'crosstest/project_logger'
require 'crosstest/configuration'
require 'crosstest/documentation_generator'

module Crosstest
  include Crosstest::Core::Logger
  include Crosstest::Core::Logging

  # File extensions that Crosstest can automatically detect/execute
  SUPPORTED_EXTENSIONS = %w(py rb js)

  class << self
    include Core::Configurable

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
      Crosstest.configuration.log_level = options.log_level || :info
      @logger = Crosstest.default_file_logger
      project_set_file = options.file || DEFAULT_PROJECT_SET_FILE
      skeptic_file = options.skeptic || DEFAULT_TEST_MANIFEST_FILE
      @basedir = File.dirname project_set_file
      Crosstest.configuration.project_set = project_set_file
      Crosstest.configuration.skeptic.manifest_file = skeptic_file
      @test_dir = options.test_dir || File.expand_path('tests/crosstest/', @basedir)
    end

    def setup
      # This autoload should probably be in Skeptic's initializer...
      autoload_crosstest_files(@test_dir) unless @test_dir.nil? || !File.directory?(@test_dir)
    end

    def scenarios(project_regexp = 'all', scenario_regexp = 'all', options = {})
      filtered_projects = filter_projects(project_regexp, options)
      filtered_projects.map(&:skeptic).flat_map do | skeptic |
        skeptic.scenarios scenario_regexp, options
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

    # Registers a {Crosstest::Skeptic::Validator} that will be used during test
    # execution on matching {Crosstest::Skeptic::Scenario}s.
    def validate(desc, scope = { suite: //, scenario: // }, &block)
      fail ArgumentError 'You must pass block' unless block_given?
      validator = Crosstest::Skeptic::Validator.new(desc, scope, &block)

      Crosstest::Skeptic::ValidatorRegistry.register validator
      validator
    end

    # @api private
    def psychic
      @psychic ||= Crosstest::Psychic.new(cwd: Crosstest.basedir, logger: logger)
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
