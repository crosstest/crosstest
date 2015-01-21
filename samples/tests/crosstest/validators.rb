require 'crosstest'

Crosstest.validate 'Hello world validator', suite: 'Katas', scenario: 'hello world' do |scenario|
  expect(scenario.result.stdout.strip).to match "Hello, world!"
end

Crosstest.validate 'Quine output matches source code', suite: 'Katas', scenario: 'quine' do |scenario|
  code = scenario.source
  output = scenario.result.stdout
  [code, output].each do | str |
    # Standardize newlines...
    str.gsub!(/[\r\n]+/, "\n")
  end
  expect(output).to eq(code)
end

Crosstest.validate 'default validator' do |scenario|
  expect(scenario.result.exitstatus).to eq(0)
  stderr = scenario.result.stderr
  stderr.gsub!(/DL is deprecated, please use Fiddle[\r\n]+/, '') # Known windows warning
  expect(stderr).to be_empty
  expect(scenario.result.stdout).to end_with /$/
end
