require 'webvalve'
require 'webmock/rspec'

RSpec.configure do |c|
  c.before do
    WebValve.setup
  end
end
