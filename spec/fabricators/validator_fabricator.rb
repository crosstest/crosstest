Fabricator(:validator, from: Crosstest::Skeptic::Validator) do
  initialize_with do
    callback = @_transient_attributes.delete :callback
    desc = @_transient_attributes.delete :description
    scope = @_transient_attributes
    @_klass.new(desc, scope, &callback)
  end # Hash based initialization
  transient description: 'Sample validator'
  transient suite: LANGUAGES.sample
  transient scenario: SCENARIO_NAMES.sample
  transient callback: Proc.new { Proc.new { |_scenario| } } # rubocop:disable Proc
end
