# Gemfile for Secure Data Storage System

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Core Rails
gem 'rails', '~> 7.1.0'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.4'
gem 'nokogiri', '< 1.16' # Known issues with >=1.16

# Security
gem 'bcrypt', '~> 3.1.7'
gem 'jwt', '~> 2.7'
gem 'rack-cors', '~> 2.0'
gem 'rack-attack', '~> 6.7'
gem 'secure_headers', '~> 6.5'

# File handling + Encryption
gem 'shrine', '~> 3.5'
gem 'aws-sdk-s3', '~> 1.0'
gem 'rbnacl', '~> 7.1'

# Performance / Caching
gem 'redis', '~> 5.0'
gem 'bootsnap', '>= 1.16.0', require: false

# Background Jobs
gem 'sidekiq', '~> 7.1'

# API / Serialization
gem 'jsonapi-serializer', '~> 2.2'
gem 'kaminari', '~> 1.2'

# Monitoring / Logging
gem 'lograge', '~> 0.14'

# Environment Variables
gem 'dotenv-rails', require: 'dotenv/load'

# Development and Test
group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
end

group :development do
  gem 'listen', '~> 3.8'
  gem 'spring'
  gem 'annotate', '~> 3.2'
end

group :test do
  gem 'shoulda-matchers', '~> 5.3'
  gem 'database_cleaner-active_record', '~> 2.1'
end
