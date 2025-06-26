source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Core Rails - Match what's in Gemfile.lock
gem 'rails', '~> 7.0.8'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.6'
gem 'nokogiri', '~> 1.13.10'

# Fix ffi version for compatibility
gem 'ffi', '~> 1.16.3'

# Security gems
gem 'bcrypt', '~> 3.1.7'  # Password hashing
gem 'jwt', '~> 2.7'       # JSON Web Tokens
gem 'rack-cors', '~> 2.0' # CORS handling

# File handling and storage
gem 'aws-sdk-s3', '~> 1.0' # S3 storage
gem 'image_processing', '~> 1.2' # Image processing

# Performance and caching
gem 'redis', '~> 4.5'     # Session store and caching (match lock version)
gem 'bootsnap', require: false # Boot performance

# Background jobs
gem 'sidekiq', '~> 5.2.10'   # Background processing (match lock version)

# API and serialization
gem 'active_model_serializers', '~> 0.10.0' # JSON serialization
gem 'fast_jsonapi' # Fast JSON API

# Rails defaults
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'

# Environment variables
gem 'dotenv-rails', require: 'dotenv/load'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 2.22'  # Match lock version
end

group :development do
  gem 'listen', '~> 3.8'
  gem 'spring'
  gem 'annotate', '~> 3.2' # Model annotations
end

group :test do
  gem 'shoulda-matchers', '~> 5.3'
  gem 'database_cleaner-active_record', '~> 2.1'
end