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
        elapsed = Benchmark.measure do
          setup
          results = parse_subcommand(args.shift, args.shift)

          run_action(:test, results)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
