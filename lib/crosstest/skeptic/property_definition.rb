module Crosstest
  module Skeptic
    class PropertyDefinition < Crosstest::Core::Dash # rubocop:disable ClassLength
      field :required, Object, default: false
      field :default, String
    end
  end
end
