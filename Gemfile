# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "propshaft"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

gem "bcrypt", "~> 3.1.7"
gem "devise", "~> 4.9"
gem "active_model_serializers", "~> 0.10.0"
gem "rack-cors"

gem "enumerize"

gem "faker"

gem "money-rails"

gem "tzinfo-data", platforms: [:windows, :jruby]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

gem "kamal", require: false

gem "thruster", require: false

gem 'data_migrate', '~> 11.3'
gem 'awesome_print', '~> 1.9', '>= 1.9.2'

group :development, :test do
  gem "debug", platforms: [:mri, :windows], require: "debug/prelude"
  gem "brakeman", require: false

  gem "rubocop-rails-omakase", require: false
  gem "rubocop-shopify", require: false
  
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
