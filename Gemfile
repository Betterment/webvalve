source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gemspec

platform :jruby do
  gem 'activerecord-jdbcsqlite3-adapter', github: 'jruby/activerecord-jdbc-adapter', branch: 'rails-5'
  gem 'jdbc-sqlite3'
end

gem 'sqlite3', '~> 1.3.10', platforms: :ruby
