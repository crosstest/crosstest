module Crosstest
  module Skeptic
    module TestTransitions
      def detect
        transition_to :detect
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
          exec!
        end
      end

      def verify
        transition_to :verify
      end

      def verify_action
        perform_action(:verify, 'Verifying') do
          verify!
        end
      end

      def destroy
        transition_to :destroy
      end

      def destroy_action
        perform_action(:destroy, 'Destroying') do
          destroy!
        end
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
        Error.formatted_trace(e).each { |line| logger.logdev.error(line) }
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
end
