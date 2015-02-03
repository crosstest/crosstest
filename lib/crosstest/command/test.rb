require 'crosstest/command'

require 'benchmark'

module Crosstest
  module Command
    # Command to test one or more instances.
    class Test < Crosstest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Crosstest (v#{Crosstest::VERSION})"
        scenarios = nil
        elapsed = Benchmark.measure do
          setup
          scenarios = parse_subcommand(args.shift, args.shift)

          run_action(scenarios, :test)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
        test_summary(scenarios)
      end

      def test_summary(scenarios)
        # TODO: Need an actual test summary
        failed_scenarios = scenarios.select do | s |
          !s.status_description.match(/Fully Verified|<Not Found>/)
        end

        shell.say
        failed_scenarios.each do | scenario |
          shell.say_status scenario.status_description, scenario.slug
        end
        status_line = "#{scenarios.size} scenarios, #{failed_scenarios.size} failures" # , x pending
        shell.say status_line
        abort unless failed_scenarios.empty?
      end
    end
  end
end
