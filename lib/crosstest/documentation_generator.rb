require 'tilt' # padrino-helpers wants you to pre-require tilt/erubis
require 'erubis'
require 'padrino-helpers'

module Crosstest
  class DocumentationGenerator
    [
      Padrino::Helpers::OutputHelpers,
      Padrino::Helpers::AssetTagHelpers,
      Padrino::Helpers::TagHelpers,
      Crosstest::Code2Doc::Helpers::CodeHelper
    ].each do | helper|
      include helper
    end

    attr_reader :scenario

    def initialize(template_file = nil, scenario = nil)
      @scenario = scenario
      @template_file = template_file
    end

    def process(scenarios)
      return nil unless File.readable? @template_file

      @scenarios = scenarios
      erb = ERB.new File.read(@template_file)
      @result = erb.result(binding) || ''
    end

    def save(target_file)
      fail 'No results to write, please call process before save' if @result.nil? || @result.empty?

      FileUtils.mkdir_p File.dirname(target_file)
      File.open(target_file, 'wb') do |f|
        f.write @result
      end
    end

    def code2doc(source_file, language = nil)
      source_code = File.read(source_file)
      segmenter_language ||= infer_language(source_file)

      buffer = StringIO.new
      segmenter_options = {
        language: language
      }
      segmenter = Crosstest::Code2Doc::CodeSegmenter.new(segmenter_options)
      segments = segmenter.segment source_code
      segments.each do |comment, code|
        comment = comment.join("\n")
        code = code.join("\n")
        code = code_block(code, language) unless code.empty?
        next if comment.empty? && code.empty?
        code = "\n#{code}\n" if !comment.empty? && !code.empty? # Markdown needs separation
        buffer.puts [comment, code].join("\n")
      end
      buffer.string
    end

    private

    def infer_language(source_file)
      language, comment_style = Code2Doc::CommentStyles.infer File.extname(source_file)
      segmenter_language = comment_style[:language] || language
    end
  end
end
