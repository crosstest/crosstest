module Crosstest
  module Skeptic
    class Result < Crosstest::Core::Dash
      extend Forwardable

      field :command, String
      field :execution_result, Crosstest::Shell::ExecutionResult
      def_delegators :execution_result, :stdout, :stderr, :exitstatus
      field :source_file, Pathname
      field :data, Hash
      field :validations, Hash[String => Validation], default: {}

      def status
        # A feature can be validated by different suites, or manually vs an automated suite.
        # That's why there's a precedence rather than boolean algebra here...
        return 'failed' if validations.values.any? { |v| v.result == :failed }
        return 'passed' if validations.values.any? { |v| v.result == :passed }
        return 'pending' if validations.values.any? { |v| v.result == :pending }
        'skipped'
      end
    end
  end
end
