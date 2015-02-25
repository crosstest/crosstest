require 'yaml'

Given(/^the (\w+) project$/) do |sdk|
  FileUtils.mkdir_p "#{current_dir}/sdks"
  FileUtils.cp_r "samples/sdks/#{sdk}", "#{current_dir}/sdks"
end

Given(/^the (\w+) omnitest config$/) do |config|
  FileUtils.cp_r "features/fixtures/configs/omnitest_#{config}.yaml", "#{current_dir}/omnitest.yaml"
end

Given(/^the (\w+) skeptic config$/) do |config|
  FileUtils.cp_r "features/fixtures/configs/skeptic_#{config}.yaml", "#{current_dir}/skeptic.yaml"
end

Then(/^the file "(.*?)" should contain yaml matching:$/) do |file, content|
  in_current_dir do
    actual_content = YAML.load(File.read(file))
    expected_content = YAML.load(content)
    expect(actual_content).to eq(expected_content)
  end
end
