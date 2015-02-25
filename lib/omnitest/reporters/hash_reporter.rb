require 'csv'

module Omnitest
  module Reporters
    class HashReporter
      def initialize(io = $stdout)
        @buffer = io
      end

      def print_table(table)
        headers = table[0]
        data = []
        table[1..-1].map do |row|
          row_data = {}
          row.each_with_index do |value, index|
            row_data[headers[index]] = value
          end
          data << row_data
        end
        @buffer.puts convert(data)
      end

      def convert(_data)
        fail 'Subclass HashReporter and convert the data to the target format'
      end

      def colors?
        false
      end
    end
  end
end
