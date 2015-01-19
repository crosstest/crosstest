module Crosstest
  module Skeptic
    describe ValidatorRegistry do
      subject(:registry) { Crosstest::Skeptic::ValidatorRegistry }

      describe '#register' do
        it 'registers a validator' do
          callback = proc do |scenario|
            expect(scenario[:result]).to_not be_nil
            expect(scenario[:result].execution_result.exitstatus).to eq(0)
          end

          expect(registry.validators).to be_empty
          registry.register(Validator.new('dummy', suite: 'java', scenario: 'hello world', &callback))
          validator = registry.validators.first
          expect(validator.suite).to eql('java')
          expect(validator.scenario).to eql('hello world')
          expect(validator.instance_variable_get('@callback')).to eql(callback)
        end
      end

      describe '#validators_for' do
        let(:java_hello_world_validator) { Fabricate(:validator, suite: 'java', scenario: 'hello world') }
        let(:java_validator) { Fabricate(:validator, suite: 'java', scenario: //) }
        let(:ruby_validator) { Fabricate(:validator, suite: 'ruby') }

        before do
          registry.register(java_hello_world_validator)
          registry.register(java_validator)
          registry.register(ruby_validator)
        end

        it 'returns registered validators that match the scope of the scenario' do
          scenario = Fabricate(:scenario, suite: 'java', name: 'hello world')
          validators = registry.validators_for scenario
          expect(validators).to include(java_hello_world_validator, java_validator)
          expect(validators).to_not include(ruby_validator)
        end
      end
    end
  end
end
