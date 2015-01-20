module Crosstest
  module Skeptic
    class Result < Crosstest::Core::Dash
      extend Forwardable

      property :execution_result # , required: true
      coerce_key :execution_result, Crosstest::Shell::ExecutionResult
      def_delegators :execution_result, :stdout, :stderr, :exitstatus
      property :source_file # , required: true
      property :data
      property :validations, default: {}
      coerce_key :validations, ::Hash[String => Validation]

      def status
        # A feature can be validated by different suites, or manually vs an automated suite.
        # That's why there's a precedence rather than boolean algebra here...
        return 'failed' if validations.values.any? { |v| v.result == 'failed' }
        return 'passed' if validations.values.any? { |v| v.result == 'passed' }
        return 'pending' if validations.values.any? { |v| v.result == 'pending' }
        'skipped'
      end
    end
  end
end
