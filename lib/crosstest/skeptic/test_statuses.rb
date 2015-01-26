module Crosstest
  module Skeptic
    module TestStatuses
      def failed?
        evidence.last_attempted_action != evidence.last_completed_action
      end

      def skipped?
        result.nil?
      end

      def sample?
        !source_file.nil?
      end

      def status
        status = last_attempted_action
        failed? ? "#{status}_failed" : status
      end

      def status_description
        case status
        when 'clone' then 'Cloned'
        when 'clone_failed' then 'Clone Failed'
        when 'detect' then 'Sample Found'
        when 'detect_failed', nil then '<Not Found>'
        when 'bootstrap' then 'Bootstrapped'
        when 'bootstrap_failed' then 'Bootstrap Failed'
        when 'detect' then 'Detected'
        when 'exec' then 'Executed'
        when 'exec_failed' then 'Execution Failed'
        when 'verify', 'verify_failed'
          validator_count = validators.count
          validation_count = validations.values.select { |v| v.result == :passed }.count
          if validator_count == validation_count
            "Fully Verified (#{validation_count} of #{validator_count})"
          else
            "Partially Verified (#{validation_count} of #{validator_count})"
          end
        # when 'verify_failed' then 'Verification Failed'
        else "<Unknown (#{status})>"
        end
      end

      def status_color
        case status_description
        when '<Not Found>' then :white
        when 'Cloned' then :magenta
        when 'Bootstrapped' then :magenta
        when 'Sample Found' then :cyan
        when 'Executed' then :blue
        when /Verified/
          if status_description =~ /Fully/
            :green
          else
            :yellow
          end
        else :red
        end
      end
    end
  end
end
