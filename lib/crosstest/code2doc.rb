require 'crosstest/code2doc/helpers/code_helper'

module Crosstest
  module Code2Doc
    class << self
      include Helpers::CodeHelper

      def file_snippet(file_name, opts = {})
        file = expand_file(file_name)
        snippet_opts = {
          language: (opts[:language] || detect_language(file))
        }.merge(opts)
        content = file_content(file_name, snippet_opts)
        snippetize(content, snippet_opts)
      end

      def scenario_output_snippet(scenario_name, opts = {})
        scenario = Crosstest.scenario(scenario_name)
        fail "Output is not available for #{scenario_name} because that scenario does not exist" unless scenario
        fail "Output is not available for #{scenario_name} because it has not been executed" unless scenario.result
        snippetize_output(scenario.result, opts)
      end

      def exec_snippet(command, opts = {})
        cwd = opts.delete(:cwd) || '.'
        psychic = Crosstest::Psychic.new(cwd: cwd)
        result = psychic.execute(command)
        snippetize_output(result, opts)
      end

      def snippetize_output(result, opts)
        include_command = (opts.key?(:include_command) ? opts.delete(:include_command) : true)
        snippet = include_command ? "$ #{result.command}\n" : ''
        snippet << result.stdout
        snippetize(snippet, opts)
      end

      def snippetize(str, opts)
        language = opts.delete(:language)
        snippet_opts = {
          format: (opts[:format] || :markdown)
        }.merge(opts)
        code_block(str, language, snippet_opts).rstrip
      end

      private

      def file_content(file_name, opts = {})
        file = expand_file(file_name)
        content = file.read
        after_pattern, before_pattern = [opts[:after], opts[:before]].map do | pattern |
          case pattern
          when nil
            nil
          when Regexp
            pattern.source
          else
            Regexp.quote(pattern.to_s)
          end
        end
        content = content.gsub(/\A.*#{after_pattern}\s*^(.*)\Z/m, '\1') if after_pattern
        content = content.gsub(/\A(.*)#{before_pattern}.*\Z/m, '\1') if before_pattern
        content.rstrip
      end

      def detect_language(file)
        file = Pathname(file)
        language, _comment_style = Code2Doc::CommentStyles.infer file.extname
        language
      rescue CommentStyles::UnknownStyleError
        nil
      end

      def expand_file(file_name)
        file = Pathname(file_name)
        file.expand_path(Crosstest.basedir) unless file.absolute?
      end
    end
  end
end
