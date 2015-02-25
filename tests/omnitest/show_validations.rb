# -*- encoding: utf-8 -*-

Omnitest.validate 'Expected output for show', suite: 'Reports', scenario: 'show' do |scenario|
  expected_output = <<-eos
katas-hello_world-ruby:                            Fully Verified (2 of 2)
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
    Hello world validator:                             ✓ Passed
    default validator:                                 ✓ Passed
  Data from spies:
eos
  cleaned_up = scenario.result.stdout.gsub(/\e\[(\d+)(;\d+)*m/, '').gsub("\r\n", "\n")
  expect(cleaned_up).to include(expected_output)
end
