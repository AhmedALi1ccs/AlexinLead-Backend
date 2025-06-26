# syntax=docker/dockerfile:1

########################### 1. BUILD STAGE ###########################
ARG RUBY_VERSION=3.1.2
FROM ruby:${RUBY_VERSION}-slim AS build

# Native-extension toolchain + headers (build-only)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential git libpq-dev libvips pkg-config \
      libsodium-dev && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_JOBS=4 BUNDLE_RETRY=3 \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=true

WORKDIR /app

# 1 ▸ Install gems (cacheable layer)
COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 \
 && bundle install \
 && bundle clean --force

# 2 ▸ Copy the rest of the application
COPY . .

########################### 2. RUNTIME STAGE ###########################
FROM ruby:${RUBY_VERSION}-slim AS runtime

# Install only runtime dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq-dev libvips pkg-config libsodium23 && \
    rm -rf /var/lib/apt/lists/*

# Copy built gems and app code from build stage
COPY --from=build /app /app
WORKDIR /app

# Entrypoint script
RUN printf '#!/bin/sh\nset -e\nrm -f /app/tmp/pids/server.pid\nexec "$@"\n' \
      > /usr/local/bin/docker-entrypoint && \
    chmod +x /usr/local/bin/docker-entrypoint

USER rails:rails
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
EXPOSE 3000