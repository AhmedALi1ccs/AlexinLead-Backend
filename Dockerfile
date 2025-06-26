FROM ruby:3.1.2

WORKDIR /app

# Install dependencies
RUN apt-get update -qq && apt-get install -y postgresql-client

# Copy Gemfile
COPY Gemfile* ./

# Install gems
RUN bundle install

# Copy app
COPY . .

# Create user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 3000

# Start app
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]