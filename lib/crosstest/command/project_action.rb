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
          if action == 'task'
            action_to_invoke = args.shift
          else
            action_to_invoke = action
          end # a bit hacky, can't we call the task method?

          project_regex = args.shift
          projects = select_projects(project_regex, options)
          run_action(projects, action_to_invoke, *args)
        end
        banner "Crosstest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
