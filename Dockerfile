# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.1.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="1" \
    RAILS_LOG_TO_STDOUT="1"

# Build stage
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Update RubyGems and Bundler to latest versions
RUN gem update --system 3.4.22 && \
    gem install bundler:2.4.22

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libvips \
    postgresql-client \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create rails user
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/log /rails/tmp /rails/storage && \
    chown -R rails:rails /rails

USER rails:rails

# Create entrypoint
COPY --chown=rails:rails docker-entrypoint.sh /rails/bin/
RUN chmod +x /rails/bin/docker-entrypoint.sh

ENTRYPOINT ["/rails/bin/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]