require 'webvalve'
require 'webmock/rspec'

RSpec.configure do |c|
  c.around do |example|
    WebValve.reset!
    example.run
  end
end
