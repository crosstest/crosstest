require 'singleton'

module Crosstest
  module Skeptic
    class ValidatorRegistry
      include Singleton

      def validators
        @validator ||= []
      end

      class << self
        def validators
          instance.validators
        end

        def register(validator, scope = {}, &callback)
          validator = Validator.new(validator, scope, &callback) if block_given?
          validators << validator
        end

        def validators_for(scenario)
          selected_validators = validators.select { |v| v.should_validate? scenario }
          selected_validators.empty? ? [Crosstest.configuration.default_validator] : selected_validators
        end

        def clear
          validators.clear
        end
      end
    end
  end
end
