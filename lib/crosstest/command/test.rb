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

          run_action(scenarios)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
        test_summary(scenarios)
      end

      def test_summary(scenarios)
        # TODO: Need an actual test summary
        failed_scenarios = scenarios.select do | s |
          !s.status_description.match(/Fully Verified|<Not Found>/)
        end
        return if failed_scenarios.empty?

        shell.say
        failed_scenarios.each do | scenario |
          shell.say_status scenario.status_description, scenario.slug
        end
        abort "#{failed_scenarios.count} tests failed"
      end
    end
  end
end
