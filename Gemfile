# Gemfile for Secure Data Storage System

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Core Rails - Be explicit about the version
gem 'rails', '~> 7.0.8'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.6'  # Downgrade to match what's being installed
gem 'nokogiri', '~> 1.13.10'  # Specify exact version that's compatible

# Security gems
gem 'bcrypt', '~> 3.1.7'
gem 'jwt', '~> 2.7'
gem 'rack-cors', '~> 2.0'

# Remove these gems that aren't in your Gemfile.lock
# gem 'rack-attack', '~> 6.7'
# gem 'secure_headers', '~> 6.5'
# gem 'shrine', '~> 3.5'
# gem 'rbnacl', '~> 7.1'
# gem 'jsonapi-serializer', '~> 2.2'
# gem 'kaminari', '~> 1.2'
# gem 'lograge', '~> 0.14'

# Add these gems that ARE in your Gemfile.lock
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'bootsnap', require: false

# File handling
gem 'aws-sdk-s3', '~> 1.0'
gem 'image_processing', '~> 1.2'

# Performance and caching
gem 'redis', '~> 4.5'  # Match installed version

# Background jobs
gem 'sidekiq', '~> 5.2.10'  # Match installed version

# API and serialization
gem 'active_model_serializers', '~> 0.10.0'
gem 'fast_jsonapi'

# Keep your existing development/test gems
gem 'dotenv-rails', groups: [:development, :test]

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 2.22'  # Match installed version
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