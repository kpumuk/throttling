require File.expand_path("../lib/throttling/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "throttling"
  spec.version = Throttling::VERSION
  spec.authors = ["Dmytro Shteflyuk", "Oleksiy Kovyrin"]
  spec.email = ["kpumuk@kpumuk.info"]

  spec.summary = "Easy throttling for Ruby applications"
  spec.description = "Throttling gem provides basic, but very powerful way to throttle various user actions in your application"
  spec.homepage = "https://github.com/kpumuk/throttling"
  spec.license = "MIT"
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(\.|(bin|test|spec|features)/)}) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13.0"
  spec.add_development_dependency "timecop", "~> 0.9.6"
  # Code style
  spec.add_development_dependency "standard", "~> 1.51.0"

  spec.cert_chain = ["certs/kpumuk.pem"]
  spec.signing_key = File.expand_path("~/.ssh/gem-kpumuk.pem") if $PROGRAM_NAME.end_with?("gem")

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/kpumuk/throttling/issues/",
    "changelog_uri" => "https://github.com/kpumuk/throttling/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/github/kpumuk/throttling/",
    "homepage_uri" => "https://github.com/kpumuk/throttling/",
    "source_code_uri" => "https://github.com/kpumuk/throttling/",
    "rubygems_mfa_required" => "true"
  }
end
