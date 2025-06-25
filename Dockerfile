FROM ruby:3.1.2-slim

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libvips pkg-config \
      libxml2-dev libxslt1-dev libffi-dev libsodium-dev \
      nodejs npm && \
    rm -rf /var/lib/apt/lists/*

RUN gem update --system 3.3.22 && \
    gem install bundler -v 2.6.2

COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 3

COPY . .

RUN echo "6bbbed9bb8d79f5b0c7281106fc48149" > config/master.key && \
    chmod 600 config/master.key

RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    mkdir -p /rails/tmp/pids

USER rails:rails

EXPOSE 3000

CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0 -p 3000"]