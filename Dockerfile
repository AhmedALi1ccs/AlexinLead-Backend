# syntax=docker/dockerfile:1

#####################################################################
#                      ───── Build stage ─────                      #
#####################################################################
ARG RUBY_VERSION=3.1.2
FROM ruby:${RUBY_VERSION}-slim AS build

# ----- OS packages required only while building native gems -----
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libpq-dev \
      libvips \
      pkg-config \
      libsodium-dev libsodium23 && \
    rm -rf /var/lib/apt/lists/*

# Bundler / RubyGems settings
ENV BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=true

WORKDIR /app

# 1) Copy dependency files first so the gem layer can be cached
COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 \
 && bundle install \
 && bundle clean --force        # safe cache cleanup

# 2) Copy the rest of the application
COPY . .

# Pre-compile only the Gemfile bootsnap cache
RUN bundle exec bootsnap precompile --gemfile

#####################################################################
#                     ───── Runtime stage ─────                     #
#####################################################################
FROM ruby:${RUBY_VERSION}-slim AS runtime

# Minimal runtime libs (no compilers)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      libvips \
      libsodium23 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy gems and application from build stage
COPY --from=build /gems /gems
COPY --from=build /app  /app

ENV BUNDLE_PATH=/gems \
    RAILS_ENV=production \
    RACK_ENV=production \
    PATH="/app/bin:$PATH" \
    XDG_CACHE_HOME=/app/tmp/cache

WORKDIR /app

# Unprivileged user
RUN useradd rails --home /app --shell /usr/sbin/nologin && \
    chown -R rails:rails /app
USER rails:rails

# Small entrypoint to clear stale PID
ENTRYPOINT ["/bin/sh", "-c", "rm -f tmp/pids/server.pid && exec \"$@\""]

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
