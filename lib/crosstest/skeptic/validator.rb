require 'rspec/expectations'

module Crosstest
  module Skeptic
    class Validator
      include RSpec::Matchers

      UNIVERSAL_MATCHER = //
      attr_reader :description, :suite, :scenario, :level, :callback

      def initialize(description, scope = {}, &validator)
        @description = description
        @suite = scope[:suite] ||= UNIVERSAL_MATCHER
        @scenario = scope[:scenario] ||= UNIVERSAL_MATCHER
        @callback = validator
      end

      def should_validate?(scenario)
        # TODO: Case-insensitive matching?
        !!(@suite.match(scenario.suite.to_s) && @scenario.match(scenario.name.to_s)) # rubocop:disable Style/DoubleNegation
      end

      def validate(scenario)
        instance_exec(scenario, &@callback) if should_validate?(scenario)
        scenario.result.validations[description] = Validation.new(result: :passed)
      rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
        validation = Validation.new(result: :failed, error: ValidationFailure.new(e.message, e))
        scenario.result.validations[description] = validation
      end

      def to_s
        @description
      end
    end
  end
end
