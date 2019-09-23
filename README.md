WebValve
========

[![Build Status](https://travis-ci.org/Betterment/webvalve.svg?branch=master)](https://travis-ci.org/Betterment/webvalve)
[![Gem Status](https://img.shields.io/gem/v/webvalve.svg)](https://rubygems.org/gems/webvalve)

WebValve is a tool for defining and registering fake implementations of
HTTP services and toggling between the real services and the fake ones
in non-production environments.

This library is made possible by the incredible gems
[WebMock](https://github.com/bblimke/webmock) and
[Sinatra](https://github.com/sinatra/sinatra).

Check out [the Rails at Scale talk](https://www.youtube.com/watch?v=Nd9hnffxCP8) for some background on why we built it and some of the key design decisions behind WebValve:

[![Rails @ Scale Talk](https://img.youtube.com/vi/Nd9hnffxCP8/0.jpg)](https://www.youtube.com/watch?v=Nd9hnffxCP8)

## Getting Started

WebValve is designed to work with Rails 4+, but it also should work with
non-Rails apps and gems.

### Installation

You can add WebValve to your Gemfile with:
```
gem 'webvalve'
```

Then run `bundle install`.

WebValve has 3 modes of operation
* enabled+intercepting - traffic associated with fakes is routed through
    fakes. all other traffic (except allowed urls) is blocked.
    SOME_SERVICE_ENABLED=1 can be used to disable faking for that
    specific service.
* enabled+allowing - all traffic is allowed. individual services can be
    routed through fakes by setting SOME_SERVICE_ENABLED=0
* disabled - traffic is not tampered with.

* in `test` environments, it's always enabled and intercepting
* in `development` environments, it's always enabled and intercepting,
    but services can be toggled on for real
* in production-like environments, it defaults to disabled, but it can
    be switched into enabled+intercepting with WEBVALVE_ENABLED=1 or
    enabled+allowing with WEBVALVE_ENABLED=0

### Network connections disabled by default

The default mode in development and test is to disallow all HTTP network
connections. This provides a clean foundation for consuming new
services. If you add a new service integration, the first thing that you
will be presented with when you attempt to hit it in development or test
is a warning that the requested URL was not mocked. This behavior comes
straight outta WebMock.

```ruby
irb(main):007:0> Net::HTTP.get(URI('http://bank.test'))

WebMock::NetConnectNotAllowedError: Real HTTP connections are disabled. Unregistered request: GET http://bank.test/ with headers {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}

You can stub this request with the following snippet:

stub_request(:get, "http://bank.test/").
  with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
  to_return(:status => 200, :body => "", :headers => {})

============================================================
```

### Creating a config file

The first thing to do is run the install generator.

```
$ rails generate webvalve:install
```

This will drop a new file in your config directory.

```ruby
# config/webvalve.rb

# # register services
#
# WebValve.register "FakeBank"
# WebValve.register "FakeExample", url: "https://api.example.org"
#
# # add urls to allowlist
#
# WebValve.allow_url "https://example.com"
```

If you're not using Rails, you can create this file for yourself.

### Registering a service

Next, you will want create a `FakeService` and register
it with the framework.

This can be accomplished by running the fake service generator:

```
$ rails generate webvalve:fake_service Bank
```

This will generate a file `fake_bank.rb` in the top-level folder
`webvalve`. This file will be autoloaded by Rails, so you can
tweak it as you go without having to restart your application.

```ruby
# webvalve/fake_bank.rb

class FakeBank < WebValve::FakeService
  # # define your routes here
  #
  # get '/widgets' do
  #   json result: 'it works!'
  # end
  #
  # # toggle this service on via ENV
  #
  # export BANK_ENABLED=true
end
```

And it will automatically register it in `config/webvalve.rb`

```ruby
# config/webvalve.rb
WebValve.register "FakeBank"
```

Again, if you're not using Rails, you'll have to create this file
yourself and update the config file manually.

You'll also want to define an environment variable for the base url of
your service.

```bash
export BANK_API_URL='http://bank.test'
```

That's it. Now when you hit your service again, it will route your
request into the `FakeBank` instance.

If you want to connect to the _actual_ service, all you have to do is
set another environment variable.

```bash
export BANK_ENABLED=true
```

You will have to restart your application after making this change
because service faking is an initialization time concern and not a
runtime concern.

## Configuring fakes in tests

In order to get WebValve fake services working properly in tests, you
have to configure WebValve at the beginning of each test. For RSpec, there
is a configuration provided. 

```ruby
# spec/spec_helper.rb
require 'webvalve/rspec'
```

If you are using 
[rspec-retry](https://github.com/NoRedInk/rspec-retry), you'll have to
manually register your around hook, instead, to ensure that WebValve
resets its configuration for each retry, e.g.:

```ruby
# spec/[rails|spec]_helper.rb

# your require lines omitted ...
require 'webmock/rspec' # set up webmock lifecycle hooks - required

RSpec.configure do |config|
  # your config lines omitted ...

  config.around :each do |ex|
    ex.run_with_retry retry: 2
  end
  
  config.around :each do |ex|
    WebValve.setup
    ex.run
  end
end
```

For any other test framework, you will want to similarly set up webmock
lifecycle hooks, and add a custom hook that will run `WebValve.setup` before
each test.

## Setting deterministic fake results in tests

Given a scenario where we want to mock a specific behavior for an
endpoint in a test, we can just use WebMock™.

```ruby
# in an rspec test...

it 'handles 404s by returning nil' do
  fake_req = stub_request('http://bank.test/some/url/1234')
    .to_return(status: 404, body: nil)

  response = Faraday.get 'http://bank.test/some/url/1234'
  expect(response.body).to be_nil
  expect(fake_req).to have_been_requested
end
```

In other scenarios where we don't care about the specific response from
the endpoint, you can just lean into the behavior you've configured for
that route in your fake service.

## Overriding conventional defaults

Sometimes a service integration may want to use an unconventional name
for its environment variables. In that case, you can register the fake
service using the optional `url:` argument.

```ruby
# config/webvalve.rb

# using an ENV variable
WebValve.register FakeBank, url: ENV.fetch("SOME_CUSTOM_API_URL")

# or with a constant value
WebValve.register FakeBank, url: "https://some-service.com"
```

## What's in a `FakeService`?

The definition of `FakeService` is really simple. It's just a
`Sinatra::Base` class. It is wired up to support returning JSON 
responses and it will raise when a route is requested but it is 
not registered.

## Frequently Asked Questions

> Can I use WebValve in environments like staging and demo?

Yes! By default WebValve is only enabled in test and development
environments; however, it can be enabled in other environments by
setting `WEBVALVE_ENABLED=true`. This can be useful for spinning up
cheap, one-off environments for user-testing or demos. When WebValve is
enabled in any environment other than development/test it will default
services to enabled rather than disabled. This ensures that
production-like environments are run integrated by default.

> Can I use WebValve without Rails?

Yep! If you're not using Rails, you'll have to load the config file
yourself. You will want to explicitly `require` each of your fake
services in your `config/webvalve.rb`, `require` your config file, and
call `WebValve.setup`  during your app's boot-up process.

## How to Contribute

We would love for you to contribute! Anything that benefits the majority
of `webvalve` users—from a documentation fix to an entirely new
feature—is encouraged.

Before diving in, [check our issue
tracker](//github.com/Betterment/webvalve/issues) and consider
creating a new issue to get early feedback on your proposed change.

### Suggested Workflow

* Fork the project and create a new branch for your contribution.
* Write your contribution (and any applicable test coverage).
* Make sure all tests pass (`bundle exec rake`).
* Submit a pull request.
