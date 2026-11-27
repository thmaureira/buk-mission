source "https://rubygems.org"

ruby "~> 3.3"

gem "rails", "~> 7.2.2"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "bootsnap", require: false
gem "rails-i18n", "~> 7.0"
gem "csv"

# Scheduled jobs (anniversaries, expirations, marking periods as taken)
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 2.0"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end
