# Use a pre-built Rails image that already has nokogiri and other gems compiled
FROM ruby:3.1.2

# Set working directory
WORKDIR /rails

# Set environment variables
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES=1 \
    RAILS_LOG_TO_STDOUT=1

# Install system dependencies that Rails needs
RUN apt-get update -qq && \
    apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Create user for security
RUN useradd --create-home --shell /bin/bash rails && \
    chown -R rails:rails /rails
USER rails

# Copy entrypoint script
COPY docker-entrypoint.sh /rails/bin/
RUN chmod +x /rails/bin/docker-entrypoint.sh

# Expose port
EXPOSE 3000

# Set entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]