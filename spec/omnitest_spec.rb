require 'spec_helper'

describe Omnitest do
  describe '.validate' do
    context 'block given' do
      it 'creates and registers a validator' do
        Omnitest.validate 'custom validator', suite: 'test', scenario: 'test' do |_scenario|
          # Validate the scenario results
        end
      end
    end
  end
end
