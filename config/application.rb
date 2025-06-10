require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module SecureDataStorage
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # Security configurations
    config.force_ssl = false  # Disabled for development
    config.ssl_options = {
      redirect: { exclude: ->(request) { request.path =~ /health/ } }
    }

    # CORS configuration - FIXED
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:5173', 'http://localhost:3000'  # Allow both Vite and standard React ports
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true,
          max_age: 86400
      end
    end

    # Rate limiting
    config.middleware.use Rack::Attack

    # Security headers
    config.middleware.use SecureHeaders::Middleware

    # Timezone
    config.time_zone = 'UTC'

    # Background jobs
    config.active_job.queue_adapter = :sidekiq
  end
end
