# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.1.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="1" \
    RAILS_LOG_TO_STDOUT="1"

# Build stage
FROM base as build

# Install ALL packages needed for Rails native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    # PostgreSQL
    libpq-dev \
    # Image processing
    libvips \
    # Package config
    pkg-config \
    # FFI dependencies
    libffi-dev \
    libsodium-dev \
    libssl-dev \
    # Nokogiri dependencies
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # Additional build tools
    autoconf \
    automake \
    libtool \
    make \
    gcc \
    g++ \
    # Other common dependencies
    curl \
    && rm -rf /var/lib/apt/lists/*

# Update RubyGems and Bundler
RUN gem update --system 3.4.22 && \
    gem install bundler:2.4.22

# Copy Gemfile files
COPY Gemfile Gemfile.lock ./

# Install gems with native extension compilation
RUN bundle config set --local deployment 'false' && \
    bundle config set --local without 'development test' && \
    bundle config set --local jobs 4 && \
    bundle config set --local retry 5 && \
    bundle config set --local force 'true' && \
    bundle install --verbose && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime libraries for ALL native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    # Image processing
    libvips \
    # PostgreSQL client
    postgresql-client \
    # FFI runtime libraries
    libffi8 \
    libsodium23 \
    libssl3 \
    # Nokogiri runtime libraries
    libxml2 \
    libxslt1.1 \
    zlib1g \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy everything from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create user and set permissions
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/log /rails/tmp /rails/storage && \
    chown -R rails:rails /rails

USER rails:rails

# Set up entrypoint
COPY --chown=rails:rails docker-entrypoint.sh /rails/bin/
RUN chmod +x /rails/bin/docker-entrypoint.sh

ENTRYPOINT ["/rails/bin/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]