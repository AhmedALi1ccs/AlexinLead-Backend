# Gemfile
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# ───── Core Rails stack ─────────────────────────────────────────
gem 'rails',        '~> 7.1.0'
gem 'pg',           '~> 1.1'
gem 'puma',         '~> 6.4'
gem 'bootsnap',     '>= 1.16.0', require: false
gem 'redis',        '~> 5.0'

# ───── Security / middleware ───────────────────────────────────
gem 'bcrypt',       '~> 3.1.7'
gem 'rack-cors',    '~> 2.0'
gem 'rack-attack',  '~> 7.0'      # 6.7+ is Rack-3 compatible

# ───── API helpers ─────────────────────────────────────────────
gem 'jsonapi-serializer', '~> 2.2'

# ───── Development & test only ─────────────────────────────────
group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'listen', '~> 3.8'
end
