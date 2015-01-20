Feature: States

  Scenario: Initial state
    Given the ruby project
    And the java project
    And the python project
    And the sample crosstest config
    And the hello_world skeptic config
    When I run `bundle exec crosstest list`
    Then the output should contain:
    """
    Test ID                   Suite  Scenario     Project  Status
    katas-hello_world-ruby    Katas  hello world  ruby     <Not Found>
    katas-hello_world-java    Katas  hello world  java     <Not Found>
    katas-hello_world-python  Katas  hello world  python   <Not Found>
    """

  @no-clobber
  Scenario: State after execution
    Given I run `bundle exec crosstest exec python`
    When I run `bundle exec crosstest list`
    Then the output should contain:
    """
    Test ID                   Suite  Scenario     Project  Status
    katas-hello_world-ruby    Katas  hello world  ruby     <Not Found>
    katas-hello_world-java    Katas  hello world  java     <Not Found>
    katas-hello_world-python  Katas  hello world  python   Executed
    """

  @no-clobber
  Scenario: State after verification
    Given I run `bundle exec crosstest verify ruby`
    When I run `bundle exec crosstest list`
    Then the output should contain:
    """
    Test ID                   Suite  Scenario     Project  Status
    katas-hello_world-ruby    Katas  hello world  ruby     Fully Verified (1 of 1)
    katas-hello_world-java    Katas  hello world  java     <Not Found>
    katas-hello_world-python  Katas  hello world  python   Executed
    """
