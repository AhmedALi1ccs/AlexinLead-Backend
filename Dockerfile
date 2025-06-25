# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.1.2
FROM registry.docker.com/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# Production environment settings
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

# Copy production environment file
COPY .env.production .env

# Copy Rails master key
RUN echo "6bbbed9bb8d79f5b0c7281106fc48149" > config/master.key

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
    chown -R rails:rails /rails && \
    mkdir -p /rails/tmp/pids && \
    chown -R rails:rails /rails/tmp

USER rails:rails

WORKDIR /rails

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Remove potential PID file\n\
rm -f /rails/tmp/pids/server.pid\n\
\n\
# Wait for database\n\
echo "Waiting for database..."\n\
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USERNAME 2>/dev/null; do\n\
  echo "Database not ready, waiting..."\n\
  sleep 2\n\
done\n\
echo "Database ready!"\n\
\n\
# Run database setup\n\
echo "Setting up database..."\n\
bin/rails db:prepare 2>/dev/null || echo "Database already set up"\n\
\n\
# Execute the main command\n\
exec "$@"' > /rails/bin/docker-entrypoint && \
    chmod +x /rails/bin/docker-entrypoint

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]