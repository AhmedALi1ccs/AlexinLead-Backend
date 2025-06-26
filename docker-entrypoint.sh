#!/bin/bash -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /rails/tmp/pids/server.pid

# Wait for database to be ready
echo "Waiting for database..."
until pg_isready -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME}; do
  echo "Database is unavailable - sleeping"
  sleep 2
done
echo "Database is ready!"

# If running the rails server then create or migrate existing database
if [ "${1}" == "./bin/rails" ] && [ "${2}" == "server" ]; then
  echo "Setting up database..."
  
  # Skip database creation for Supabase (database already exists)
  # Just check if we can connect
  echo "Checking database connection..."
  if bundle exec rails db:version > /dev/null 2>&1; then
    echo "Database connection successful!"
  else
    echo "Setting up database schema..."
    # Try to create database, but don't fail if it already exists
    bundle exec rails db:create 2>/dev/null || echo "Database already exists (this is normal for Supabase)"
  fi
  
  # Run migrations
  echo "Running database migrations..."
  bundle exec rails db:migrate
  
  # Seed database if needed (only in non-production or if SEED_DB is set)
  if [ "${RAILS_ENV}" != "production" ] || [ "${SEED_DB}" = "true" ]; then
    echo "Seeding database..."
    bundle exec rails db:seed
  fi
  
  echo "Database setup complete!"
fi

# Execute the main command
exec "${@}"