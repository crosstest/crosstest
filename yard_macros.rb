require 'hashie'

module Crosstest
  module Core
    class Dash < Hashie::Dash
      # @api private
      # @!macro [attach] field
      #   @!attribute [rw] $1
      #     Attribute $1. $3
      #     @return [$2]
      # Dummy method to load macro, see crosstest-core for the actual implementation
      def self.field(_name, _type, _opts = {})
      end

      # @api private
      # @!macro [attach] required_field
      #   @!attribute [rw] $1
      #     **Required** Attribute $1. $3
      #     @return [$2]
      # Dummy method to load macro, see crosstest-core for the actual implementation
      def self.required_field(_name, _type, _opts = {})
      end
    end
  end
end
