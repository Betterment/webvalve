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

  s.files = Dir["{lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 4.2"
  s.add_dependency "sinatra", "~> 2.0"
  s.add_dependency "sinatra-contrib", "~> 2.0"
  s.add_dependency "webmock", "~> 2.0"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry"
  s.add_development_dependency "yard"

  s.required_ruby_version = ">= 2"
end
