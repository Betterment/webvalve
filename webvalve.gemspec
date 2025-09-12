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

  s.add_dependency "activesupport", ">= 6.0"
  s.add_dependency "sinatra", ">= 1.4"
  s.add_dependency "sinatra-contrib", ">= 1.4"
  s.add_dependency "webmock", ">= 2.0"

  s.add_development_dependency "appraisal", "~> 2.5.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "yard"

  s.required_ruby_version = ">= 3.2"

  s.post_install_message = <<~MSG
    Thanks for installing WebValve!

    Note for upgraders: If you're upgrading from a version less than 2.0, service
    URL behavior has changed. Please verify that your app isn't relying on the
    previous behavior:

    1. `*` characters are now interpreted as wildcards, enabling dynamic URL
       segments. In the unlikely event that your URLs use `*` literals, you'll need
       to URL encode them (`%2A`) both in your URL spec and at runtime.

    2. URL suffix matching is now strict. For example, `BAR_URL=http://bar.co` will
       no longer match `https://bar.com`, but it will match `http://bar.co/foo`. If
       you need to preserve the previous behavior, you can add a trailing `*` to
       your URL spec, e.g. `BAR_URL=http://bar.co*`.
  MSG
end
