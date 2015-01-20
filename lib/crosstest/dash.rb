require 'hashie'

module Crosstest
  module Core
    class Dash < Hashie::Dash
      include Hashie::Extensions::Coercion

      def initialize(hash = {})
        super Crosstest::Core::Util.symbolized_hash(hash)
      end

      # @api private
      # @!macro [attach] field
      #   @!attribute [rw] $1
      #     Swagger field $1. $3
      #     @return [$2]
      # Defines a Swagger field on a class.
      def self.field(name, type, opts = {})
        property name, opts
        coerce_key name, type
      end

      # @api private
      # @!macro [attach] required_field
      #   @!attribute [rw] $1
      #     **Required** Swagger field $1. $3
      #     @return [$2]
      # Defines a required Swagger field on a class.
      def self.required_field(name, type, opts = {})
        opts[:required] = true
        field(name, type, opts)
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

    class Mash < Hashie::Mash
      include Hashie::Extensions::Coercion
    end
  end
end
