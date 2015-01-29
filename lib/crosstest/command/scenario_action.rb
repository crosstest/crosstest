require 'benchmark'

module Crosstest
  module Command
    class ScenarioAction < Crosstest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Crosstest (v#{Crosstest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          scenarios = parse_subcommand(args.shift, args.shift)
          run_action(scenarios)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
