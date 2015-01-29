require 'crosstest/reporters'
module Crosstest
  module Command
    class List < Crosstest::Command::Base
      include Crosstest::Reporters

      def call
        setup
        @reporter = Crosstest::Reporters.reporter(options[:format], shell)
        tests = parse_subcommand(args.shift, args.shift)

        table = [header_row]
        table += tests.map do | scenario |
          row(scenario)
        end
        print_table(table)
      end

      private

      def header_row
        row = []
        row << colorize('Suite', :green)
        row << colorize('Scenario', :green)
        row << colorize('Project', :green)
        row << colorize('Status', :green)
        row << colorize('Source', :green) if options[:source]
        row
      end

      def row(scenario)
        row = []
        row << color_pad(scenario.suite)
        row << color_pad(scenario.name)
        row << color_pad(scenario.psychic.name)
        row << format_status(scenario)
        if options[:source]
          source_file = scenario.absolute_source_file ? relativize(scenario.absolute_source_file, Dir.pwd) : colorize('<No code sample>', :red)
          row << source_file
        end
        row
      end

      def print_table(*args)
        @reporter.print_table(*args)
      end

      def colorize(string, *args)
        return string unless @reporter.respond_to? :set_color
        @reporter.set_color(string, *args)
      end

      def color_pad(string)
        string + colorize('', :white)
      end

      def format_status(scenario)
        colorize(scenario.status_description, scenario.status_color)
      end
    end
  end
end
