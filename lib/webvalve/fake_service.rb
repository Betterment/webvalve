require 'sinatra/base'
require 'sinatra/json'
require 'webvalve/instrumentation/middleware'

module WebValve
  class FakeService < Sinatra::Base

    set :dump_errors, false
    set :show_exceptions, false
    set :raise_errors, true

    configure do
      use Instrumentation::Middleware
    end

    private

    def route_missing
      raise "route not defined for #{request.request_method} #{uri} in #{self.class.name}."
    end
  end
end
