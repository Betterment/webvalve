$:.push File.expand_path("../lib", __FILE__)

require "webvalve/version"

Gem::Specification.new do |s|
  s.name        = "webvalve"
  s.version     = WebValve::VERSION
  s.authors     = ["Sam Moore"]
  s.email       = ["sam@betterment.com"]
  s.homepage    = "https://github.com/Betterment/webvalve"
  s.summary     = "A library for faking http service integrations in development and test"
  s.description = "Betterment's library for developing and testing service-oriented apps in isolation with WebMock and Sinatra-based fakes."
  s.license     = "MIT"
  s.metadata = {
    "rubygems_mfa_required" => "true",
  }

  s.files = Dir["{lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activesupport", ">= 5.2.0"
  s.add_dependency "sinatra", ">= 1.4", "< 3"
  s.add_dependency "sinatra-contrib", ">= 1.4", "< 3"
  s.add_dependency "webmock", ">= 2.0"

  s.add_development_dependency "appraisal", "~> 2.2.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "yard"

  s.required_ruby_version = ">= 2.6.0"
end
