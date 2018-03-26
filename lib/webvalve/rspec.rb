require 'webvalve'
require 'webmock/rspec'

RSpec.configure do |c|
  c.around do |example|
    WebValve.setup
    example.run
  end
end
