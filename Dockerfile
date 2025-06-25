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
    BUNDLE_WITHOUT="development test"

#-----------------------------------------
# Builder stage: compile gems & assets
#-----------------------------------------
FROM base AS build

# Install system dependencies for native gems, including FFI and libsodium headers
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libvips pkg-config \
      libxml2-dev libxslt1-dev libffi-dev libsodium-dev && \
    rm -rf /var/lib/apt/lists/*

# Update RubyGems and install exact Bundler
RUN gem update --system 3.3.22 && \
    gem install bundler -v 2.6.2

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy the rest of the app
COPY . .

# Precompile bootsnap caches for faster boot
RUN bundle exec bootsnap precompile app/ lib/

#-----------------------------------------
# Final stage: runtime image
#-----------------------------------------
FROM base

# Install runtime packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy installed gems and application code from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user and set permissions
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails
USER rails:rails

# Update working directory inside final image
WORKDIR /rails

# Expose the Rails default port
EXPOSE 3000

# Start Rails server directly
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]