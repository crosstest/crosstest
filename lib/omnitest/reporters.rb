module Omnitest
  module Reporters
    autoload :MarkdownReporter, 'omnitest/reporters/markdown_reporter'
    # autoload :HTMLReporter, 'omnitest/reporters/html_reporter'
    autoload :JSONReporter, 'omnitest/reporters/json_reporter'
    autoload :YAMLReporter, 'omnitest/reporters/yaml_reporter'

    RESOURCES_DIR = File.expand_path '../../../resources/', __FILE__
    GENERATORS_DIR = File.expand_path 'generators/', RESOURCES_DIR
    ASSETS_DIR = File.expand_path 'assets/', RESOURCES_DIR

    def self.reporter(format, shell)
      case format
      when 'text'
        shell
      when 'markdown'
        MarkdownReporter.new
      when 'json'
        JSONReporter.new
      when 'yaml'
        YAMLReporter.new
      else
        fail "Unknown report format #{format}"
      end
    end
  end
end
