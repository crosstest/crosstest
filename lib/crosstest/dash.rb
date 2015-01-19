require 'hashie/dash'
require 'hashie/extensions/coercion'

module Crosstest
  class Dash < Hashie::Dash
    include Hashie::Extensions::Coercion

    def initialize(hash = {})
      super Crosstest::Core::Util.symbolized_hash(hash)
    end
  end

  class ManifestSection < Crosstest::Dash
  end
end
