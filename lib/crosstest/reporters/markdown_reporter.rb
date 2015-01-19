module Crosstest
  module Reporters
    class MarkdownReporter
      include Crosstest::Core::Util::String
      def initialize(io = $stdout)
        @buffer = io
      end

      def print_table(table)
        @buffer.puts # Markdown tables don't always render properly without a break
        header_data = table[0]
        header_line = header_data.join ' | '
        @buffer.puts header_line
        @buffer.puts header_line.gsub(/[^|]/, '-')

        table[1..-1].each do |data_line|
          @buffer.puts data_line.map { |line| escape_html(line) }.join(' | ')
        end
      end

      def colors?
        false
      end
    end
  end
end
