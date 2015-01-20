
require 'rspec/support'
require 'rspec/expectations'

module Crosstest
  RESOURCES_DIR = File.expand_path '../../../resources', __FILE__

  class Configuration < Crosstest::Core::Dash
    property :dry_run,      default: false
    property :log_root,     default: '.crosstest/logs'
    property :log_level,    default: :info
    property :projects, default: []
    # coerce_key :projects, Crosstest::Project

    # TODO: This should probably be configurable, or tied to Thor color options.
    if RSpec.respond_to?(:configuration)
      RSpec.configuration.color = true
    else
      RSpec::Expectations.configuration.color = true
    end

    def default_logger
      @default_logger ||= ProjectLogger.new(stdout: $stdout, level: env_log)
    end

    def project_set
      @project_set ||= load_project_set('crosstest.yaml')
    end

    def project_set=(project_set_data)
      if project_set_data.is_a? Skeptic::TestManifest
        @project_set = project_set_data
      else
        @project_set = ProjectSet.from_yaml project_set_data
      end
      @project_set
    rescue Errno::ENOENT => e
      raise UserError, "Could not load test manifest: #{e.message}"
    end

    alias_method :load_project_set, :project_set=

    def manifest
      @manifest ||= load_manifest('skeptic.yaml')
    end

    def manifest=(manifest_data)
      if manifest_data.is_a? Skeptic::TestManifest
        @manifest = manifest_data
      else
        @manifest = Skeptic::TestManifest.from_yaml manifest_data
      end
      @manifest
    rescue Errno::ENOENT => e
      raise UserError, "Could not load test manifest: #{e.message}"
    end

    alias_method :load_manifest, :manifest=

    # The callback used to validate code samples that
    # don't have a custom validator.  The default
    # checks that the sample code runs successfully.
    def default_validator_callback
      @default_validator_callback ||= proc do |scenario|
        expect(scenario[:result].execution_result.exitstatus).to eq(0)
      end
    end

    def default_validator
      @default_validator ||= Skeptic::Validator.new('default validator', suite: //, scenario: //, &default_validator_callback)
    end

    attr_writer :default_validator_callback

    def register_spy(spy)
      Crosstest::Skeptic::Spies.register_spy(spy)
    end

    private

    # Determine the default log level from an environment variable, if it is
    # set.
    #
    # @return [Integer,nil] a log level or nil if not set
    # @api private
    def env_log
      level = ENV['CROSSTEST_LOG'] && ENV['CROSSTEST_LOG'].downcase.to_sym
      level = Crosstest::Core::Util.to_logger_level(level) unless level.nil?
      level
    end
  end
end
