require 'hashie/dash'
require 'hashie/extensions/coercion'

module Crosstest
  class Dash < Hashie::Dash
    include Hashie::Extensions::Coercion

    def initialize(hash = {})
      super Crosstest::Core::Util.symbolized_hash(hash)
    end

    module Loadable
      include Core::DefaultLogger
      def from_yaml(yaml_file)
        logger.debug "Loading #{yaml_file}"
        raw_content = File.read(yaml_file)
        processed_content = ERB.new(raw_content).result
        data = YAML.load processed_content
        new data
      end
    end
  end
end
