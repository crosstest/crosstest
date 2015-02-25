require 'json'
require 'omnitest/reporters/hash_reporter'

module Omnitest
  module Reporters
    class JSONReporter < HashReporter
      def convert(data)
        JSON.pretty_generate data
      end
    end
  end
end
