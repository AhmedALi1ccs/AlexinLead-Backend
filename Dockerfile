# syntax=docker/dockerfile:1

###########################
#      Build stage        #
###########################
ARG RUBY_VERSION=3.1.2
FROM ruby:${RUBY_VERSION}-slim AS build

# ——— essential OS packages just for building native gems ———
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libpq-dev \
      libvips \
      pkg-config \
      libsodium-dev \
      libsodium23 && \
    rm -rf /var/lib/apt/lists/*

# Stop Bundler from installing docs and keep gems in /gems (cacheable layer)
ENV BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=true

WORKDIR /app

# 1 ▼ Copy only Gemfiles first → better cache utilisation
COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 && \
    bundle install && \
    # clean up Bundler & gem caches
    rm -rf "$(bundle info --path)/cache" /root/.bundle/cache

# 2 ▼ Now copy the rest of the application
COPY . .

# Pre-compile bootsnap cache (both gemfile & app code)
RUN bundle exec bootsnap precompile --gemfile && \
    bundle exec bootsnap precompile app/ lib/

###########################
#     Runtime stage       #
###########################
FROM ruby:${RUBY_VERSION}-slim AS runtime

# Only runtime libs
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      libvips \
      libsodium23 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy gems and app from the build stage
COPY --from=build /gems /gems
COPY --from=build /app /app

ENV BUNDLE_PATH=/gems \
    RAILS_ENV=production \
    RACK_ENV=production \
    PATH="/app/bin:$PATH" \
    # bootsnap needs proper tmp
    XDG_CACHE_HOME=/app/tmp/cache

WORKDIR /app

# ─── create unprivileged user ───
RUN useradd rails --home /app --shell /usr/sbin/nologin && \
    chown -R rails:rails /app

USER rails:rails

# ─── tiny entrypoint clearing stale pid ───
ENTRYPOINT ["/bin/sh", "-c", "rm -f tmp/pids/server.pid && exec \"$@\""]
EXPOSE 3000

# Allow passing RAILS_MASTER_KEY at build or runtime
ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY:-}

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
