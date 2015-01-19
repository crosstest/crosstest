require 'benchmark'

module Crosstest
  module Command
    class Action < Crosstest::Command::Base
      include RunAction

      IMPLEMENTOR_ACTIONS = [:clone, :bootstrap, :task] # These are run once per project, not per test

      # Invoke the command.
      def call
        banner "Starting Crosstest (v#{Crosstest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          tests = parse_subcommand(args.shift, args.shift)
          projects = tests.map(&:project).uniq
          if IMPLEMENTOR_ACTIONS.include? action # actions on projects
            run_action(action, projects)
          else # actions on tests
            run_action(action, tests)
          end
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
