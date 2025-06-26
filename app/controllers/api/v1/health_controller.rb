class Api::V1::HealthController < ApplicationController
  skip_before_action :authenticate_request
  
  def check
    # Check database connection
    database_status = check_database
    
    # Check Redis connection (if using Redis)
    redis_status = check_redis
    
    # Overall health status
    healthy = database_status[:healthy] && redis_status[:healthy]
    
    status_code = healthy ? :ok : :service_unavailable
    
    render json: {
      status: healthy ? 'healthy' : 'unhealthy',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || '1.0.0',
      environment: Rails.env,
      checks: {
        database: database_status,
        redis: redis_status
      }
    }, status: status_code
  end
  
  # Simple endpoint for load balancer health checks
  def ping
    render json: { status: 'ok', timestamp: Time.current.iso8601 }
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { healthy: true, message: 'Database connection successful' }
  rescue => e
    { healthy: false, message: "Database connection failed: #{e.message}" }
  end
  
  def check_redis
    if defined?(Redis) && ENV['REDIS_URL'].present?
      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.ping
      { healthy: true, message: 'Redis connection successful' }
    else
      { healthy: true, message: 'Redis not configured' }
    end
  rescue => e
    { healthy: false, message: "Redis connection failed: #{e.message}" }
  end
end