require 'benchmark'

module Omnitest
  module Command
    class ScenarioAction < Omnitest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Omnitest (v#{Omnitest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          scenarios = parse_subcommand(args.shift, args.shift)
          run_action(scenarios, action, options[:concurrency])
        end
        banner "Omnitest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
