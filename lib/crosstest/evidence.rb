require 'hashie'

module Crosstest
  class EvidenceFileLoadError < StandardError; end
  class Evidence < Crosstest::Dash
    attr_reader :file_name
    attr_writer :autosave

    property :last_attempted_action
    property :last_completed_action
    property :result
    coerce_key :result, Crosstest::Result
    property :spy_data, default: {}
    property :error
    property :vars, default: {}
    # coerce_key :vars, Crosstest::Manifest::Environment
    property :duration

    # KEYS_TO_PERSIST = [:result, :spy_data, :error, :vars, :duration]

    def initialize(file_name, initial_data = {})
      @file_name = file_name
      super initial_data
    end

    def []=(key, value)
      super
      save if autosave?
    end

    def autosave?
      @autosave == true
    end

    def self.load(file_name, initial_data)
      if File.exist?(file_name)
        existing_data = Hashie::Mash.load(file_name)
        initial_data.merge!(existing_data)
      end
      Evidence.new(file_name, initial_data)
    end

    def save
      dir = File.dirname(file_name)
      serialized_string = serialize_hash(Core::Util.stringified_hash(to_hash))

      FileUtils.mkdir_p(dir)
      File.open(file_name, 'wb') { |f| f.write(serialized_string) }
    end

    def destroy
      @data = nil
      FileUtils.rm_f(file_name) if File.exist?(file_name)
    end

    private

    attr_reader :file_name

    # @api private
    def serialize_hash(hash)
      ::YAML.dump(hash)
    end
  end
end
