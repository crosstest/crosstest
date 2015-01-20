Feature: Boostrapping

  Crosstest uses the [script/bootstrap](http://wynnnetherland.com/linked/2013012801/bootstrapping-consistency) pattern to prepare projects for testing. You can hook into any package manager, compiler, build tool, or any other toolchain to prepare to build and run samples.

  Scenario: Bootstrapping all projects
    Given the ruby project
    And the java project
    And the python project
    And the sample crosstest config
    And the hello_world skeptic config
    When I run `bundle exec crosstest bootstrap`
    Then the output should contain "-----> Bootstrapping java"
    Then the output should contain "-----> Bootstrapping python"
    Then the output should contain "-----> Bootstrapping ruby"

  Scenario: Bootstrapping selected projects
    Given the ruby project
    And the java project
    And the python project
    And the sample crosstest config
    And the hello_world skeptic config
    When I run `bundle exec crosstest bootstrap "(java|ruby)"`
    Then the output should contain "-----> Bootstrapping java"
    Then the output should not contain "-----> Bootstrapping python"
    Then the output should contain "-----> Bootstrapping ruby"

  Scenario: Bootstrapping by scenario
    Given the ruby project
    And the java project
    And the python project
    And the sample crosstest config
    And the hello_world skeptic config
    When I run `bundle exec crosstest bootstrap all hello`
    Then the output should contain "-----> Bootstrapping java"
    Then the output should contain "-----> Bootstrapping python"
    Then the output should contain "-----> Bootstrapping ruby"
