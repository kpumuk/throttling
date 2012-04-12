# -*- encoding: utf-8 -*-
require File.expand_path('../lib/throttling/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmytro Shteflyuk", "Oleksiy Kovyrin"]
  gem.email         = ["kpumuk@kpumuk.info"]
  gem.description   = %q{Throttling gem provides basic, but very powerful way to throttle various user actions in your application}
  gem.summary       = %q{Easy throttling for Ruby applications}
  gem.homepage      = "https://github.com/kpumuk/throttling"

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent'
  gem.add_development_dependency 'growl'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "throttling"
  gem.require_paths = ["lib"]
  gem.version       = Throttling::VERSION
end
