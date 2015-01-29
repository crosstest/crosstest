module Crosstest
  module Skeptic
    autoload :ScenarioDefinition, 'crosstest/skeptic/scenario_definition'
    autoload :PropertyDefinition, 'crosstest/skeptic/property_definition'
    autoload :Scenario, 'crosstest/skeptic/scenario'
    autoload :TestStatuses, 'crosstest/skeptic/test_statuses'
    autoload :TestTransitions, 'crosstest/skeptic/test_transitions'
    autoload :TestManifest, 'crosstest/skeptic/test_manifest'
    autoload :Evidence, 'crosstest/skeptic/evidence'
    autoload :Result, 'crosstest/skeptic/result'
    autoload :Spy, 'crosstest/skeptic/spy'
    autoload :Spies, 'crosstest/skeptic/spies'
    autoload :Validation, 'crosstest/skeptic/validation'
    autoload :Validator, 'crosstest/skeptic/validator'
    autoload :ValidatorRegistry, 'crosstest/skeptic/validator_registry'
  end
end
