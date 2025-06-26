# syntax=docker/dockerfile:1

########################### 1. BUILD STAGE ###########################
ARG RUBY_VERSION=3.1.2
FROM ruby:${RUBY_VERSION}-slim AS build

# Native-extension toolchain + headers (build-only)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential git libpq-dev libvips pkg-config \
      libsodium-dev libsodium23 && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_JOBS=4 BUNDLE_RETRY=3 \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=true

WORKDIR /app

# 1 ▸ install gems (cacheable layer)
COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 \
 && bundle install \
 && bundle clean --force

# 2 ▸ copy the rest of the application
COPY . .

########################### 2. RUNTIME STAGE ##########################
FROM ruby:${RUBY_VERSION}-slim AS runtime

# Only what we need at runtime
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 libvips libsodium23 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Bring in gems and code
COPY --from=build /gems /gems
COPY --from=build /app  /app

ENV BUNDLE_PATH=/gems \
    RAILS_ENV=production RACK_ENV=production \
    PATH="/app/bin:$PATH" \
    XDG_CACHE_HOME=/app/tmp/cache

WORKDIR /app

# Unprivileged user
RUN useradd rails --home /app --shell /usr/sbin/nologin && \
    chown -R rails:rails /app
USER rails:rails

# Clear stale PID at container start
ENTRYPOINT ["/bin/sh", "-c", "rm -f tmp/pids/server.pid && exec \"$@\""]
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
