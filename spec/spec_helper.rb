require 'simplecov'
SimpleCov.start

require 'omnitest'
require 'fabrication'
require 'thor_spy'
require 'aruba'
require 'aruba/api'

# Config required for project
RSpec.configure do | config |
  config.include Aruba::Api
  config.before(:example) do
    @aruba_timeout_seconds = 30
    clean_current_dir
  end
end

RSpec.configure do |c|
  c.before(:each) do
    Omnitest.reset
  end
  c.expose_current_running_example_as :example
end

# For Fabricators
LANGUAGES = %w(java ruby python nodejs c# golang php)
SCENARIO_NAMES = [
  'hello world',
  'quine',
  'my_kata'
]
