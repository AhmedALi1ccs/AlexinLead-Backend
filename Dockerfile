# syntax=docker/dockerfile:1

#####################################################################
#                      ───── Build stage ─────                      #
#####################################################################
ARG RUBY_VERSION=3.1.2
FROM ruby:${RUBY_VERSION}-slim AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential git libpq-dev libvips pkg-config \
      libsodium-dev libsodium23 && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/gems \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    NOKOGIRI_USE_SYSTEM_LIBRARIES=true

WORKDIR /app

# ---------- 1. install gems (cacheable layer) ----------
COPY Gemfile Gemfile.lock ./
RUN gem update --system 3.3.22 \
 && bundle install \
 && bundle clean --force            # legit cache cleanup

# ---------- 2. copy app code ----------
COPY . .

# (Optional gem-path cache is fine; precompiling app code is what fails)
RUN bundle exec bootsnap precompile --gemfile

#####################################################################
#                     ───── Runtime stage ─────                     #
#####################################################################
FROM ruby:${RUBY_VERSION}-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 libvips libsodium23 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /gems /gems
COPY --from=build /app  /app

ENV BUNDLE_PATH=/gems \
    RAILS_ENV=production \
    RACK_ENV=production \
    PATH="/app/bin:$PATH" \
    XDG_CACHE_HOME=/app/tmp/cache

WORKDIR /app

RUN useradd rails --home /app --shell /usr/sbin/nologin && \
    chown -R rails:rails /app
USER rails:rails

ENTRYPOINT ["/bin/sh", "-c", "rm -f tmp/pids/server.pid && exec \"$@\""]
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
