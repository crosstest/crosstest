Feature: States

  Scenario: Initial state
    Given the ruby project
    And the java project
    And the python project
    And the sample omnitest config
    And the hello_world skeptic config
    When I run `bundle exec omnitest list`
    Then the output should contain:
    """
    Suite  Scenario     Project  Status
    Katas  hello world  ruby     <Not Found>
    Katas  hello world  java     <Not Found>
    Katas  hello world  python   <Not Found>
    """

  @no-clobber
  Scenario: State after execution
    Given I run `bundle exec omnitest exec python`
    When I run `bundle exec omnitest list`
    Then the output should contain:
    """
    Suite  Scenario     Project  Status
    Katas  hello world  ruby     <Not Found>
    Katas  hello world  java     <Not Found>
    Katas  hello world  python   Executed
    """

  @no-clobber
  Scenario: State after verification
    Given I run `bundle exec omnitest verify ruby`
    When I run `bundle exec omnitest list`
    Then the output should contain:
    """
    Suite  Scenario     Project  Status
    Katas  hello world  ruby     Fully Verified (1 of 1)
    Katas  hello world  java     <Not Found>
    Katas  hello world  python   Executed
    """
