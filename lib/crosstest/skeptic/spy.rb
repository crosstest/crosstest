module Crosstest
  module Skeptic
    # # @abstract
    class Spy
      def initialize(app, opts = {})
        @app = app
        @opts = opts
      end

      def call(_scenario)
        fail NotImplementedError, 'Subclass must implement #call'
      end

      def self.reports
        @reports ||= {}
      end

      def self.report(type, report_class)
        reports[type] = report_class
      end
    end
  end
end
