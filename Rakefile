begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

if Rails.env.development? || Rails.env.test?
  if defined? Dummy
    task(:default).clear
    if ENV['APPRAISAL_INITIALIZED'] || ENV['TRAVIS']
      require 'rspec/core'
      require 'rspec/core/rake_task'
      RSpec::Core::RakeTask.new(:spec)
      task default: :spec
    else
      require 'appraisal'
      Appraisal::Task.new
      task default: :appraisal
    end
  end
end

require 'yard'
YARD::Rake::YardocTask.new
