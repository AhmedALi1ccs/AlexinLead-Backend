require_relative "boot"

require 'logger' unless defined?(Logger)  # ✅ Add this

require "rails/all"

Bundler.require(*Rails.groups)

module SecureDataStorage
  class Application < Rails::Application
    config.load_defaults 7.0
    config.api_only = true

    # Security configurations
    config.force_ssl = Rails.env.production?
    config.ssl_options = {
      redirect: { exclude: ->(request) { request.path =~ /health/ } }
    }

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true,
          max_age: 86400
      end
    end

    # Remove these lines - gems not installed:
    # config.middleware.use Rack::Attack
    # config.middleware.use SecureHeaders::Middleware

    # Timezone
    config.time_zone = 'UTC'

    # Background jobs
    config.active_job.queue_adapter = :sidekiq
  end
end