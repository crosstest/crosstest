require 'benchmark'
require 'crosstest/code2doc/helpers/code_helper'

# TODO: This class really needs to be split-up - and probably renamed.
#
# There's a few things happening here:
#   There's the "Scenario" - probably better named "Scenario" - this
#   is *what* we want to test, i.e. "Fog - Upload Directory". It should
#   only rely on parsing crosstest.yaml.
#
#   Then there's the "Code Sample" - the code to be tested to verify the
#   scenario. This can probably be moved to Psychic, since Psychic finds
#   and executes the code samples.
#
#   And the result or "State File" - this stores and persists the test
#   results and data captured by spies during test.
#
#   Finally, there's the driver, including the FSM class at the bottom of
#   this file. It's responsible for managing the test lifecycle.

module Crosstest
  class Scenario < Crosstest::Dash # rubocop:disable ClassLength
    include Crosstest::Core::FileSystem
    include Crosstest::Core::Logging
    include Crosstest::Core::Util::String
    # View helpers
    include Crosstest::Code2Doc::Helpers::CodeHelper

    property :name
    property :project, required: true
    coerce_key :project, Crosstest::Project
    property :suite, required: true
    property :source_file
    coerce_key :source_file, Pathname
    property :basedir
    coerce_key :basedir, Pathname
    property :vars, default: {}
    # coerce_key :vars, Crosstest::TestManifest::Environment

    extend Forwardable
    def_delegators :evidence, :save
    KEYS_TO_PERSIST = [:last_attempted_action, :last_completed_action, :result,
                       :spy_data, :error, :duration]
    KEYS_TO_PERSIST.each do |key|
      def_delegators :evidence, key.to_sym, "#{key}=".to_sym
    end

    def [](key)
      return evidence[key] if KEYS_TO_PERSIST.include?(key.to_sym)
      super
    end

    def []=(key, value)
      return evidence[key] = value if KEYS_TO_PERSIST.include?(key.to_sym)
      super
    end

    def initialize(hash)
      evidence_hash = {}
      KEYS_TO_PERSIST.each do |key|
        evidence_hash[key] = hash.delete(key)
      end
      super
      evidence(evidence_hash)
      self.basedir ||= project.basedir
    end

    def runner
      @runner ||= Crosstest::Psychic.new(cwd: basedir, logger: logger, env: environment_variables)
    end

    def environment_variables
      global_vars = begin
        Crosstest.manifest[:global_env].dup
      rescue
        {}
      end
      global_vars.merge(vars.dup)
    end

    def evidence(initial_data = {})
      evidence_file = Pathname.new(Dir.pwd).join('.crosstest', "#{slug}.yaml").expand_path
      @evidence ||= Skeptic::Evidence.load(evidence_file, initial_data)
    end

    def validators
      Crosstest::Skeptic::ValidatorRegistry.validators_for self
    end

    def logger
      project.logger
    end

    def full_name
      [suite, name].join ' :: '
    end

    def slug
      slugify(suite, name, project.name)
    end

    def absolute_source_file
      return nil if source_file.nil?

      File.expand_path source_file, basedir
    end

    def detect
      transition_to :detect
    end

    def detect!
      fail FeatureNotImplementedError, "Project #{name} has not been cloned" unless project.cloned?
      self.source_file = runner.find_sample(name)
      fail FeatureNotImplementedError, name if source_file.nil?
      fail FeatureNotImplementedError, name unless File.exist?(absolute_source_file)
    rescue Errno::ENOENT
      raise FeatureNotImplementedError, name
    end

    def detect_action
      perform_action(:detect, 'Detecting code sample') do
        detect!
      end
    end

    def exec
      transition_to :exec
    end

    def exec_action
      perform_action(:exec, 'Executing') do
        detect!
        evidence.result = run_scenario
      end
    end

    def run_scenario(spies = Crosstest::Skeptic::Spies)
      spies.observe(self) do
        execution_result = runner.run_sample(source_file.to_s)
        evidence.result = Skeptic::Result.new(execution_result: execution_result, source_file: source_file.to_s)
      end
      result
    rescue Crosstest::Shell::ExecutionError => e
      execution_error = ExecutionError.new(e)
      execution_error.execution_result = e.execution_result
      evidence.error = Crosstest::Error.formatted_trace(e).join("\n")
      raise execution_error
    end

    def verify
      transition_to :verify
    end

    def destroy
      transition_to :destroy
    end

    def test(_destroy_mode = :passing)
      elapsed = Benchmark.measure do
        banner "Cleaning up any prior instances of #{slug}"
        destroy
        banner "Testing #{slug}"
        verify
        # destroy if destroy_mode == :passing
      end
      info "Finished testing #{slug} #{Core::Util.duration(elapsed.real)}."
      evidence.duration = elapsed.real
      save
      evidence = nil # it's saved, free up memory...
      self
      # ensure
      # destroy if destroy_mode == :always
    end

    def destroy_action
      perform_action(:destroy, 'Destroying') do
        @evidence.destroy
        @evidence = nil
      end
    end

    def verify_action
      perform_action(:verify, 'Verifying') do
        validators.each do |validator|
          validation = validator.validate(self)
          status = case validation.result
                   when :passed
                     Core::Color.colorize("\u2713 Passed", :green)
                   when :failed
                     Core::Color.colorize('x Failed', :red)
                     Crosstest.handle_validation_failure(validation.error)
                   else
                     Core::Color.colorize(validation.result, :yellow)
                   end
          info format('%-50s %s', validator.description, status)
        end
      end
    end

    def perform_action(verb, output_verb)
      banner "#{output_verb} #{slug}..."
      elapsed = action(verb) { yield }
      # elapsed = action(verb) { |state| driver.public_send(verb, state) }
      info("Finished #{output_verb.downcase} #{slug}" \
        " #{Core::Util.duration(elapsed.real)}.")
      # yield if block_given?
      self
    end

    def action(what, &block)
      evidence.last_attempted_action = what.to_s
      elapsed = Benchmark.measure do
        block.call(@state)
      end
      evidence.last_completed_action = what.to_s
      elapsed
    rescue Crosstest::FeatureNotImplementedError => e
      raise e
    rescue ActionFailed => e
      log_failure(what, e)
      raise(ScenarioFailure, failure_message(what) +
        "  Please see .crosstest/logs/#{name}.log for more details",
            e.backtrace)
    rescue Exception => e # rubocop:disable RescueException
      log_failure(what, e)
      raise ActionFailed,
            "Failed to complete ##{what} action: [#{e.message}]", e.backtrace
    ensure
      save unless what == :destroy
    end

    def failed?
      evidence.last_attempted_action != evidence.last_completed_action
    end

    def skipped?
      result.nil?
    end

    def sample?
      !source_file.nil?
    end

    def status
      status = last_attempted_action
      failed? ? "#{status}_failed" : status
    end

    def status_description
      case status
      when 'clone' then 'Cloned'
      when 'clone_failed' then 'Clone Failed'
      when 'detect' then 'Sample Found'
      when 'detect_failed', nil then '<Not Found>'
      when 'bootstrap' then 'Bootstrapped'
      when 'bootstrap_failed' then 'Bootstrap Failed'
      when 'detect' then 'Detected'
      when 'exec' then 'Executed'
      when 'exec_failed' then 'Execution Failed'
      when 'verify', 'verify_failed'
        validator_count = validators.count
        validation_count = validations.values.select { |v| v.result == :passed }.count
        if validator_count == validation_count
          "Fully Verified (#{validation_count} of #{validator_count})"
        else
          "Partially Verified (#{validation_count} of #{validator_count})"
        end
      # when 'verify_failed' then 'Verification Failed'
      else "<Unknown (#{status})>"
      end
    end

    def status_color
      case status_description
      when '<Not Found>' then :white
      when 'Cloned' then :magenta
      when 'Bootstrapped' then :magenta
      when 'Sample Found' then :cyan
      when 'Executed' then :blue
      when /Verified/
        if status_description =~ /Fully/
          :green
        else
          :yellow
        end
      else :red
      end
    end

    def validations
      return nil if result.nil?
      result.validations
    end

    def transition_to(desired)
      transition_result = nil
      begin
        FSM.actions(last_completed_action, desired).each do |transition|
          transition_result = send("#{transition}_action")
        end
      rescue Crosstest::FeatureNotImplementedError
        warn("#{slug} is not implemented")
      rescue ActionFailed => e
        # Need to use with_friendly_errors again somewhere, since errors don't bubble up
        # without fast-fail?
        Crosstest.handle_error(e)
        raise(ScenarioFailure, e.message, e.backtrace)
      end
      transition_result
    end

    def log_failure(what, _e)
      return if logger.logdev.nil?

      logger.logdev.error(failure_message(what))
      # TODO: Maybe this should be restored...
      # Error.formatted_trace(e).each { |line| logger.logdev.error(line) }
    end

    # Returns a string explaining what action failed, at a high level. Used
    # for displaying to end user.
    #
    # @param what [String] an action
    # @return [String] a failure message
    # @api private
    def failure_message(what)
      "#{what.capitalize} failed for test #{slug}."
    end

    # The simplest finite state machine pseudo-implementation needed to manage
    # an Instance.
    #
    # @api private
    class FSM
      # Returns an Array of all transitions to bring an Instance from its last
      # reported transistioned state into the desired transitioned state.
      #
      # @param last [String,Symbol,nil] the last known transitioned state of
      #   the Instance, defaulting to `nil` (for unknown or no history)
      # @param desired [String,Symbol] the desired transitioned state for the
      #   Instance
      # @return [Array<Symbol>] an Array of transition actions to perform
      # @api private
      def self.actions(last = nil, desired)
        last_index = index(last)
        desired_index = index(desired)

        if last_index == desired_index || last_index > desired_index
          Array(TRANSITIONS[desired_index])
        else
          TRANSITIONS.slice(last_index + 1, desired_index - last_index)
        end
      end

      TRANSITIONS = [:destroy, :detect, :exec, :verify]

      # Determines the index of a state in the state lifecycle vector. Woah.
      #
      # @param transition [Symbol,#to_sym] a state
      # @param [Integer] the index position
      # @api private
      def self.index(transition)
        if transition.nil?
          0
        else
          TRANSITIONS.find_index { |t| t == transition.to_sym }
        end
      end
    end
  end
end
