# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in secretmgr.gemspec
gemspec

gem "base64"
gem "multi_json"
gem "ykutils"
gem "ykxutils", path: "../ykxutils"

group :test, :development, optional: true do
  gem 'rspec', '~> 3.0'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'debug', platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem 'rufo'
  gem 'yard'
end
