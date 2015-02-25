require 'yaml'
require 'omnitest/reporters/hash_reporter'

module Omnitest
  module Reporters
    class YAMLReporter < HashReporter
      def convert(data)
        YAML.dump data
      end
    end
  end
end
