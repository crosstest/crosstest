require 'benchmark'

module Crosstest
  module Command
    class ProjectAction < Crosstest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Crosstest (v#{Crosstest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          project_regex = args.shift
          projects = select_projects(project_regex, options)
          run_action(projects, action, *args)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
