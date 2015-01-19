require 'hashie/dash'

module Crosstest
  module Skeptic
    class Validation < Crosstest::ManifestSection
      # TODO: Should we have (expectation) 'failed' vs (unexpected) 'error'?
      ALLOWABLE_STATES = %w(passed pending failed skipped)

      property :result, required: true
      property :error
      property :error_source

      def result=(state)
        state = state.to_s
        fail invalidate_state_error unless ALLOWABLE_STATES.include? state
        super
      end

      ALLOWABLE_STATES.each do |state|
        define_method "#{state}?" do
          result == state?
        end
      end

      def to_hash(*args)
        self.error_source = error.error_source if error.respond_to? :error_source
        super
      end

      protected

      def invalidate_state_error(state)
        ArgumentError.new "Invalid result state: #{state}, should be one of #{ALLOWABLE_STATES.inspect}"
      end
    end
  end
end
