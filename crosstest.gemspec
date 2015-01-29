# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crosstest/version'

Gem::Specification.new do |spec|
  spec.name          = 'crosstest'
  spec.version       = Crosstest::VERSION
  spec.authors       = ['Max Lincoln']
  spec.email         = ['max@devopsy.com']
  spec.summary       = 'A polyglot test runner for sample code'
  spec.description   = 'A polyglot test runner for sample code'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'crosstest-core', '~> 0'
  spec.add_dependency 'crosstest-psychic', '>= 0.0.4'
  spec.add_dependency 'logging', '~> 1.8'
  spec.add_dependency 'mixlib-shellout', '~> 1.3' # Used for MRI
  spec.add_dependency 'buff-shell_out', '~> 0.1'  # Used for JRuby
  spec.add_dependency 'rspec-expectations', '~> 3.0'
  spec.add_dependency 'padrino-helpers', '~> 0.12'
  spec.add_dependency 'erubis', '~> 2.7'
  spec.add_dependency 'haml', '~> 4.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'aruba', '~> 0.5'
  spec.add_development_dependency 'rubocop', '~> 0.18', '<= 0.27'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.2'
  spec.add_development_dependency 'fabrication', '~> 2.11'
end
