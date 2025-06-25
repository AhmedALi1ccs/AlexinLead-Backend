# syntax=docker/dockerfile:1

# Use official Ruby image matching .ruby-version
ARG RUBY_VERSION=3.1.2
FROM registry.docker.com/library/ruby:${RUBY_VERSION}-slim AS base

# Set the working directory for the Rails app
WORKDIR /rails

# Ensure production environment and Bundler settings
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

#-----------------------------------------
# Builder stage: compile gems & assets
#-----------------------------------------
FROM base AS build

# Install system dependencies for native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libvips \
      pkg-config \
      libxml2-dev \
      libxslt1-dev \
      libffi-dev \
      libsodium-dev \
      nodejs \
      npm && \
    rm -rf /var/lib/apt/lists/*

# Update RubyGems and install exact Bundler version
RUN gem update --system 3.3.22 && \
    gem install bundler -v 2.6.2

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap caches and Rails assets
RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

#-----------------------------------------
# Final stage: runtime image
#-----------------------------------------
FROM base AS final

# Install only runtime packages (no build tools)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libvips \
      postgresql-client \
      libxml2 \
      libxslt1.1 \
      libffi8 \
      libsodium23 && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user before copying files
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails && \
    chown -R rails:rails /rails

# Copy installed gems and application code from build stage
COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

# Switch to non-root user
USER rails:rails

# Set working directory
WORKDIR /rails

# Entrypoint and default command
ENTRYPOINT ["bin/docker-entrypoint"]

# Expose the Rails default port
EXPOSE 3000

# Default command to start the Rails server
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]