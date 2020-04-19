begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

task(:default).clear
if ENV['APPRAISAL_INITIALIZED'] || ENV['CI']
  require 'rspec/core'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
else
  require 'appraisal'
  Appraisal::Task.new
  task default: :appraisal
end

require 'yard'
YARD::Rake::YardocTask.new
