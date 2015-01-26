require 'yaml'

module Crosstest
  module Skeptic
    # Crosstest::TestManifest acts as a test manifest. It defines the test scenarios that should be run,
    # and may be shared across multiple projects when used for a compliance suite.
    #
    # A manifest is generally defined and loaded from YAML. Here's an example manifest:
    #   ---
    #   global_env:
    #     LOCALE: <%= ENV['LANG'] %>
    #     FAVORITE_NUMBER: 5
    #   suites:
    #     Katas:
    #       env:
    #         NAME: 'Max'
    #       samples:
    #         - hello world
    #         - quine
    #     Tutorials:
    #           env:
    #           samples:
    #             - deploying
    #             - documenting
    #
    # The *suites* object defines the tests. Each object, under suites, like *Katas* or *Tutorials* in this
    # example, represents a test suite. A test suite is subdivided into *samples*, that each act as a scenario.
    # The *global_env* object and the *env* under each suite define (and standardize) the input for each test.
    # The *global_env* values will be made available to all tests as environment variables, along with the *env*
    # values for that specific test.
    #
    class TestManifest < Crosstest::Core::Dash
      include Core::DefaultLogger
      include Crosstest::Core::Logging
      extend Crosstest::Core::Dash::Loadable

      class Environment < Crosstest::Core::Mash
        coerce_value Integer, String
      end

      class Suite < Crosstest::Core::Dash
        field :env, Environment, default: {}
        field :samples, Array[String], required: true
        field :results, Hash
      end

      field :global_env, Environment
      field :suites, Hash[String => Suite]

      attr_accessor :scenarios

      def scenarios
        @scenarios ||= {}
      end

      def build_scenarios(projects)
        suites.each do | suite_name, suite |
          suite.samples.each do | sample |
            projects.each_value do | project |
              scenario = project.build_scenario suite: suite_name, name: sample, vars: suite.env
              scenarios[scenario.slug] = scenario
            end
          end
        end
      end
    end
  end
end
