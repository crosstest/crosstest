Feature: Show

  Scenario: Initial state
    Given the ruby project
    And the java project
    And the python project
    And the sample crosstest config
    And the hello_world skeptic config
    When I run `bundle exec crosstest show ruby 'hello world'`
    Then the output should contain:
    """
    katas-hello_world-ruby:                            <Not Found>
      Test suite:                                        Katas
      Test scenario:                                     hello world
      Project:                                           ruby
      Source:                                            sdks/ruby/katas/hello_world.rb
    """

  @no-clobber
  Scenario: State after testing
    Given I run `bundle exec crosstest test ruby`
    When I run `bundle exec crosstest show ruby 'hello world'`
    Then the output should contain:
    """
    katas-hello_world-ruby:                            Fully Verified (1 of 1)
      Test suite:                                        Katas
      Test scenario:                                     hello world
      Project:                                           ruby
      Source:                                            sdks/ruby/katas/hello_world.rb
      Execution result:
        Exit Status:                                       0
        Stdout:
          Hello, world!
        Stderr:
      Validations:
        default validator:                                 ✓ Passed
      Data from spies:
    """
