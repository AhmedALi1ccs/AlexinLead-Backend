FROM ruby:3.1.2

WORKDIR /app

# Install ALL dependencies for native gems
RUN apt-get update -qq && \
    apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    zlib1g-dev

# Copy Gemfile
COPY Gemfile* ./

# Force clean bundle install
RUN rm -rf /usr/local/bundle/gems/* && \
    bundle config set --local force_ruby_platform true && \
    bundle install

# Copy app
COPY . .

# Create user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 3000

# Start app
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]