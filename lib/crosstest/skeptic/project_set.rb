require 'yaml'
require 'hashie/mash'
require 'hashie/extensions/coercion'
require 'hashie/extensions/deep_merge'

module Crosstest
  # Crosstest::ProjectSet defines a set of projects that will be used for cross-project tasks
  # and tests. It is generally defined and loaded from crosstest.yaml. Here's an example project set:
  #
  # @example Project set defined in crosstest.yaml
  #     ---
  #     projects:
  #       ruby:
  #         language: 'ruby'
  #         basedir: 'sdks/ruby'
  #         git:
  #           repo: 'https://github.com/crosstest/ruby_samples'
  #       java:
  #         language: 'java'
  #         basedir: 'sdks/java'
  #         git:
  #           repo: 'https://github.com/crosstest/java_samples'
  #       python:
  #         language: 'python'
  #         basedir: 'sdks/python'
  #         git:
  #           repo: 'https://github.com/crosstest/python_samples'
  #
  # The *suites* object defines the tests. Each object, under suites, like *Katas* or *Tutorials* in this
  # example, represents a test suite. A test suite is subdivided into *samples*, that each act as a scenario.
  # The *global_env* object and the *env* under each suite define (and standardize) the input for each test.
  # The *global_env* values will be made available to all tests as environment variables, along with the *env*
  # values for that specific test.
  #
  class ProjectSet < Crosstest::Dash
    include Core::DefaultLogger
    include Crosstest::Core::Logging
    include Hashie::Extensions::DeepMerge

    property :projects, required: true
    coerce_key :projects, Hashie::Hash[String => Crosstest::Project]

    def initialize(hash = {})
      super
      projects.each do | name, project |
        project.name = name
      end
    end

    # Parses a YAML file to create a {TestManifest} object.
    def self.from_yaml(yaml_file)
      logger.debug "Loading #{yaml_file}"
      raw_content = File.read(yaml_file)
      processed_content = ERB.new(raw_content).result
      data = YAML.load processed_content
      new data
    end
  end
end
