class Rack::Attack
  # Throttle login attempts
  throttle('login/ip', limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Throttle API requests per IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Block suspicious requests
  blocklist('block suspicious') do |req|
    # Block if User-Agent is suspicious
    req.user_agent =~ /curl|wget|python-requests/i
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Rate limit exceeded', retry_after: retry_after }.to_json]
    ]
  end
end
