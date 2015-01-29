require 'crosstest/reporters'

module Crosstest
  module Command
    class Show < Crosstest::Command::Base # rubocop:disable Metrics/ClassLength
      include Crosstest::Reporters
      include Crosstest::Core::Util::String
      include Crosstest::Core::FileSystem

      def initialize(cmd_args, cmd_options, options = {})
        @indent_level = 0
        super
      end

      def call
        setup
        @reporter = Crosstest::Reporters.reporter(options[:format], shell)
        scenarios = parse_subcommand(args.shift, args.shift)

        scenarios.each do | scenario |
          status_color = scenario.status_color.to_sym
          status(scenario.slug, colorize(scenario.status_description, status_color), status_color)
          indent do
            status('Test suite', scenario.suite)
            status('Test scenario', scenario.name)
            status('Project', scenario.psychic.name)
            source_file = if scenario.absolute_source_file
                            Core::FileSystem.relativize(scenario.absolute_source_file, Dir.pwd)
                          else
                            colorize('<No code sample>', :red)
                          end
            status('Source', source_file)
            display_source(scenario)
            display_execution_result(scenario)
            display_validations(scenario)
            display_spy_data(scenario)
          end
        end
      end

      private

      def reformat(string)
        return if string.nil? || string.empty?

        indent do
          string.gsub(/^/, indent)
        end
      end

      def indent
        if block_given?
          @indent_level += 2
          result = yield
          @indent_level -= 2
          result
        else
          ' ' * @indent_level
        end
      end

      def display_source(test)
        return if !options[:source] || !test.source?

        shell.say test.highlighted_code
      end

      def display_execution_result(test)
        return if test.result.nil? || test.result.execution_result.nil?

        execution_result = test.result.execution_result
        status 'Execution result'
        indent do
          status('Exit Status', execution_result.exitstatus)
          status 'Stdout'
          say reformat(execution_result.stdout)
          status 'Stderr'
          say reformat(execution_result.stderr)
        end
      end

      def display_validations(test)
        return if test.validations.nil?

        status 'Validations'
        indent do
          test.validations.each do | name, validation |
            status(name, indicator(validation))
            indent do
              status 'Error message', validation.error if validation.error
              unless !options[:source] || !validation.error_source?
                status 'Validator source'
                say highlight(validation.error_source, language: 'ruby')
              end
            end
          end
        end
      end

      def display_spy_data(test)
        return if test.spy_data.nil?

        status 'Data from spies'
        indent do
          test.spy_data.each do |_spy, data|
            indent do
              data.each_pair do |k, v|
                status(k, v)
              end
            end
          end
        end
      end

      def say(msg)
        shell.say msg if msg
      end

      def status(status, msg = nil, color = :cyan, colwidth = 50)
        msg = yield if block_given?
        shell.say(indent)
        status = shell.set_color("#{status}:", color, true)
        # The built-in say_status is right-aligned, we want left-aligned
        shell.say format("%-#{colwidth}s %s", status, msg).rstrip
      end

      def print_table(*args)
        @reporter.print_table(*args)
      end

      def colorize(string, *args)
        return string unless @reporter.respond_to? :set_color
        @reporter.set_color(string, *args)
      end

      def color_pad(string)
        string + colorize('', :white)
      end

      def indicator(validation)
        case validation.result
        when :passed
          colorize("\u2713 Passed", :green)
        when :failed
          colorize('x Failed', :red)
        else
          colorize(validation.result, :yellow)
        end
      end
    end
  end
end
