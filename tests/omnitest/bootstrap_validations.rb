# -*- encoding: utf-8 -*-

Omnitest.validate 'Bootstraps java and ruby, but not python', suite: 'CLI', scenario: 'bootstrap' do |scenario|
  expect(scenario.result.stdout).to include('-----> Bootstrapping java')
  expect(scenario.result.stdout).to include('-----> Bootstrapping ruby')
  expect(scenario.result.stdout).to_not include('-----> Bootstrapping python')
end
