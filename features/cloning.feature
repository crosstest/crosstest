@wip
Feature: Cloning

  Omnitest can clone projects from git.

  Scenario: Cloning all projects
    Given the sample omnitest config
    When I run `bundle exec omnitest clone`
    Then the output should contain "-----> Cloning java"
    Then the output should contain "-----> Cloning python"
    Then the output should contain "-----> Cloning ruby"

  Scenario: Cloning selected projects
    Given the ruby project
    And the java project
    And the python project
    And the sample omnitest config
    When I run `bundle exec omnitest clone "(java|ruby)"`
    Then the output should contain "-----> Cloning java"
    Then the output should not contain "-----> Cloning python"
    Then the output should contain "-----> Cloning ruby"

  Scenario: Cloning by scenario
    Given the ruby project
    And the java project
    And the python project
    And the sample omnitest config
    And the hello_world skeptic config
    When I run `bundle exec omnitest clone hello`
    Then the output should contain "-----> Cloning java"
    Then the output should contain "-----> Cloning python"
    Then the output should contain "-----> Cloning ruby"
