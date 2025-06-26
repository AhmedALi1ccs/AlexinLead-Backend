#!/bin/bash
set -e

# Remove server.pid
rm -f /app/tmp/pids/server.pid

# Wait for database
echo "Waiting for database..."
until pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USERNAME; do
  sleep 2
done

# Run migrations
echo "Running migrations..."
bundle exec rails db:create db:migrate

# Start server
echo "Starting server..."
exec "$@"