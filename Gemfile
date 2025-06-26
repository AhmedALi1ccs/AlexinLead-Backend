# Gemfile for Secure Data Storage System
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# ───── Core Rails stack ─────────────────────────────────────────
gem 'rails',      '~> 7.1.0'
gem 'pg',         '~> 1.1'
gem 'puma',       '~> 6.4'

# ───── Security & middleware ───────────────────────────────────
gem 'bcrypt',      '~> 3.1.7'    # password hashing
gem 'jwt',         '~> 2.7'      # JSON Web Tokens
gem 'rack-cors',   '~> 2.0'      # CORS handling
gem 'rack-attack', '~> 6.7'      # ≥ 6.7 supports Rack 3 (Rails 7.1)
gem 'secure_headers', '~> 6.5'   # sets CSP / HSTS, etc.

# ───── File handling / encryption ──────────────────────────────
gem 'shrine',      '~> 3.5'      # file uploads
gem 'aws-sdk-s3',  '~> 1.0'
gem 'rbnacl',      '~> 7.1'      # symmetric & public-key crypto

# ───── Performance / background / caching ──────────────────────
gem 'redis',       '~> 5.0'
gem 'bootsnap',    '>= 1.16.0', require: false
gem 'sidekiq',     '~> 7.1'

# ───── API helpers ─────────────────────────────────────────────
gem 'jsonapi-serializer', '~> 2.2'
gem 'kaminari',           '~> 1.2'

# ───── Monitoring / logging ────────────────────────────────────
gem 'lograge',     '~> 0.14'

# ───── Env management ─────────────────────────────────────────


# ───── Development & test groups ───────────────────────────────
group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'dotenv-rails', require: 'dotenv/load'
end

group :development do
  gem 'listen',  '~> 3.8'
  gem 'spring'
  gem 'annotate', '~> 3.2'
end

group :test do
  gem 'shoulda-matchers',           '~> 5.3'
  gem 'database_cleaner-active_record', '~> 2.1'
end
