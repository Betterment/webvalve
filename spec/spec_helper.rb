require 'bundler'
Bundler.require :default, :development

if defined?(Rails)
  ENV['RAILS_ENV'] ||= 'test'
  require_relative 'dummy/config/application'
  puts "Testing against Rails #{Rails.gem_version}"
else
  puts 'Testing without Rails'
end

require 'rspec'
require 'pry'
require 'webvalve'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  config.profile_examples = 10

  config.include Helpers
end
