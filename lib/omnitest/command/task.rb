require 'benchmark'

module Omnitest
  module Command
    class Task < Omnitest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Omnitest (v#{Omnitest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          task = args.shift
          project_regex = args.shift
          projects = Omnitest.filter_projects(project_regex)
          if options[:exec]
            run_action(projects, :execute, options[:concurrency])
          else
            run_action(projects, task, options[:concurrency])
          end
        end
        #  Need task summary...
        banner "Omnitest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
