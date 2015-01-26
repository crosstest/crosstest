require 'English'

module Crosstest
  # All Crosstest errors and exceptions.
  module Error
    # Creates an array of strings, representing a formatted exception,
    # containing backtrace and nested exception info as necessary, that can
    # be viewed by a human.
    #
    # For example:
    #
    #     ------Exception-------
    #     Class: Crosstest::StandardError
    #     Message: Failure starting the party
    #     ---Nested Exception---
    #     Class: IOError
    #     Message: not enough directories for a party
    #     ------Backtrace-------
    #     nil
    #     ----------------------
    #
    # @param exception [::StandardError] an exception
    # @return [Array<String>] a formatted message
    def self.formatted_trace(exception)
      arr = formatted_exception(exception).dup
      last = arr.pop
      if exception.respond_to?(:original) && exception.original
        arr += formatted_exception(exception.original, 'Nested Exception')
        last = arr.pop
      end
      arr += ['Backtrace'.center(22, '-'), exception.backtrace, last].flatten
      arr
    end

    # Creates an array of strings, representing a formatted exception that
    # can be viewed by a human. Thanks to MiniTest for the inspiration
    # upon which this output has been designed.
    #
    # For example:
    #
    #     ------Exception-------
    #     Class: Crosstest::StandardError
    #     Message: I have failed you
    #     ----------------------
    #
    # @param exception [::StandardError] an exception
    # @param title [String] a custom title for the message
    #   (default: `"Exception"`)
    # @return [Array<String>] a formatted message
    def self.formatted_exception(exception, title = 'Exception')
      [
        title.center(22, '-'),
        "Class: #{exception.class}",
        "Message: #{exception.message}",
        ''.center(22, '-')
      ]
    end
  end

  module ErrorSource
    def error_source
      if backtrace_locations
        source_from_backtrace(backtrace_locations)
      elsif original && original.backtrace_locations
        source_from_backtrace(original.backtrace_locations)
      end
    end

    def source_from_backtrace(backtrace_locations)
      error_location = backtrace_locations.delete_if { |l| l.absolute_path =~ /gems\/rspec-/ }.first
      error_source = File.read(error_location.absolute_path)
      error_lineno = error_location.lineno - 1 # lineno counts from 1
      get_dedented_block(error_source, error_lineno)
    end

    def get_dedented_block(source_text, target_lineno)
      block = []
      lines = source_text.lines
      target_indent = lines[target_lineno][/\A */].size
      lines[0...target_lineno].reverse.each do |line|
        indent = line[/\A */].size
        block.prepend line
        break if indent < target_indent
      end
      lines[target_lineno..lines.size].each do |line|
        indent = line[/\A */].size
        block.push line
        break if indent < target_indent
      end
      block.join
    end
  end

  # Base exception class from which all Crosstest exceptions derive. This class
  # nests an exception when this class is re-raised from a rescue block.
  class StandardError < ::StandardError
    include Error

    # @return [::StandardError] the original (wrapped) exception
    attr_reader :original

    # Creates a new StandardError exception which optionally wraps an original
    # exception if given or detected by checking the `$!` global variable.
    #
    # @param msg [String] exception message
    # @param original [::StandardError] an original exception which will be
    #   wrapped (default: `$ERROR_INFO`)
    def initialize(msg, original = $ERROR_INFO)
      super(msg)
      @original = original
    end
  end

  # Base exception class for all exceptions that are caused by user input
  # errors.
  class UserError < StandardError; end

  # Base exception class for all exceptions that are caused by incorrect use
  # of an API.
  class ClientError < StandardError; end

  # Base exception class for exceptions that are caused by external library
  # failures which may be temporary.
  class TransientFailure < StandardError; end

  # Exception class for any exceptions raised when performing an scenario
  # action.
  class ActionFailed < TransientFailure; end

  # FIXME: Move to skeptic
  module Skeptic
    # Exception class capturing what caused an scenario to die.
    class ScenarioFailure < TransientFailure; end
  end

  # Exception class capturing what caused a validation to fail.
  class ValidationFailure < TransientFailure
    include ErrorSource
  end

  class ExecutionError < TransientFailure
    attr_accessor :execution_result
  end

  class FeatureNotImplementedError < StandardError
    def initialize(feature)
      super "Feature #{feature} is not implemented"
    end
  end

  class << self
    # Yields to a code block in order to consistently emit a useful crash/error
    # message and exit appropriately. There are two primary failure conditions:
    # an expected scenario failure, and any other unexpected failures.
    #
    # **Note** This method may call `Kernel.exit` so may not return if the
    # yielded code block raises an exception.
    #
    # ## Scenario Failure
    #
    # This is an expected failure scenario which could happen if an scenario
    # couldn't be created, a Chef run didn't successfully converge, a
    # post-convergence test suite failed, etc. In other words, you can count on
    # encountering these failures all the time--this is Crosstest's worldview:
    # crash early and often. In this case a cleanly formatted exception is
    # written to `STDERR` and the exception message is written to
    # the common Crosstest file logger.
    #
    # ## Unexpected Failure
    #
    # All other forms of `Crosstest::Error` exceptions are considered unexpected
    # or unplanned exceptions, typically from user configuration errors, driver
    # or provisioner coding issues or bugs, or internal code issues. Given
    # a stable release of Crosstest and a solid set of drivers and provisioners,
    # the most likely cause of this is user configuration error originating in
    # the `.crosstest.yaml` setup. For this reason, the exception is written to
    # `STDERR`, a full formatted exception trace is written to the common
    # Crosstest file logger, and a message is displayed on `STDERR` to the user
    # informing them to check the log files and check their configuration with
    # the `crosstest diagnose` subcommand.
    #
    # @raise [SystemExit] if an exception is raised in the yielded block
    def with_friendly_errors
      yield
    rescue Crosstest::Skeptic::ScenarioFailure => e
      Crosstest.mutex.synchronize do
        handle_scenario_failure(e)
      end
      exit 10
    rescue Crosstest::Error => e
      Crosstest.mutex.synchronize do
        handle_error(e)
      end
      exit 20
    end

    # Handles an scenario failure exception.
    #
    # @param e [StandardError] an exception to handle
    # @see Crosstest.with_friendly_errors
    # @api private
    def handle_scenario_failure(e)
      stderr_log(e.message.split(/\s{2,}/))
      stderr_log(Error.formatted_exception(e.original))
      file_log(:error, e.message.split(/\s{2,}/).first)
      debug_log(Error.formatted_trace(e))
    end

    alias_method :handle_validation_failure, :handle_scenario_failure

    # Handles an unexpected failure exception.
    #
    # @param e [StandardError] an exception to handle
    # @see Crosstest.with_friendly_errors
    # @api private
    def handle_error(e)
      stderr_log(Error.formatted_exception(e))
      stderr_log('Please see .crosstest/logs/crosstest.log for more details')
      # stderr_log("Also try running `crosstest diagnose --all` for configuration\n")
      file_log(:error, Error.formatted_trace(e))
    end

    private

    # Writes an array of lines to the common Crosstest logger's file device at the
    # given severity level. If the Crosstest logger is set to debug severity, then
    # the array of lines will also be written to the console output.
    #
    # @param level [Symbol,String] the desired log level
    # @param lines [Array<String>] an array of strings to log
    # @api private
    def file_log(level, lines)
      Array(lines).each do |line|
        if Crosstest.logger.debug?
          Crosstest.logger.debug(line)
        else
          Crosstest.logger.logdev && Crosstest.logger.logdev.public_send(level, line)
        end
      end
    end

    # Writes an array of lines to the `STDERR` device.
    #
    # @param lines [Array<String>] an array of strings to log
    # @api private
    def stderr_log(lines)
      Array(lines).each do |line|
        $stderr.puts(Core::Color.colorize(">>>>>> #{line}", :red))
      end
    end

    # Writes an array of lines to the common Crosstest debugger with debug
    # severity.
    #
    # @param lines [Array<String>] an array of strings to log
    # @api private
    def debug_log(lines)
      Array(lines).each { |line| Crosstest.logger.debug(line) }
    end
  end
end
