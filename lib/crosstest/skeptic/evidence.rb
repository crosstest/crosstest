require 'pstore'

module Crosstest
  module Skeptic
    class EvidenceFileLoadError < StandardError; end
    class Evidence < Crosstest::Core::Dash
      attr_reader :file
      attr_writer :autosave

      field :last_attempted_action, String
      field :last_completed_action, String
      field :result, Result
      field :spy_data, Hash, default: {}
      field :error, Object
      field :vars, TestManifest::Environment, default: {}
      field :duration, Numeric

      # KEYS_TO_PERSIST = [:result, :spy_data, :error, :vars, :duration]

      def initialize(file, initial_data = {})
        @file = Pathname(file)
        FileUtils.mkdir_p(@file.dirname)
        super initial_data
      end

      def []=(key, value)
        super
        save if autosave?
      end

      def autosave?
        @autosave == true
      end

      def self.load(file, initial_data = {})
        new(file, initial_data).tap(&:reload)
      end

      def reload
        store.transaction do
          store.roots.each do | key |
            self[key] = store[key]
          end
        end
      end

      def save
        store.transaction do
          keys.each do | key |
            store[key] = self[key]
          end
        end
      end

      def destroy
        @store = nil
        file.delete
      end

      private

      def store
        @store ||= PStore.new(file)
      end

      # @api private
      def serialize_hash(hash)
        ::YAML.dump(hash)
      end
    end
  end
end
