require 'benchmark'

module Omnitest
  module Command
    class ProjectAction < Omnitest::Command::Base
      include RunAction

      # Invoke the command.
      def call
        banner "Starting Omnitest (v#{Omnitest::VERSION})"
        elapsed = Benchmark.measure do
          setup
          project_regex = args.shift
          if %w(task workflow).include? action # a bit hacky...
            argument = project_regex
            project_regex = args.shift
            args.unshift argument
          end
          projects = select_projects(project_regex, options)
          run_action(projects, action, options[:concurrency], *args)
        end
        banner "Omnitest is finished. #{Core::Util.duration(elapsed.real)}"
      end
    end
  end
end
