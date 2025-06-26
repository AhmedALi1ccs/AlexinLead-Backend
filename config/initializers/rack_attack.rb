# config/initializers/rack_attack.rb
# ---------------------------------------------------------------
require 'rack/attack'                         # make sure the gem is loaded
Rails.application.config.middleware.use Rack::Attack   # insert into stack

# ───────────────────── Rate-limit rules ─────────────────────────

# 1. Login attempts: 5 POSTs to /api/v1/auth/login per 15 minutes per IP
Rack::Attack.throttle('logins/ip', limit: 5, period: 15.minutes) do |req|
  req.ip if req.path == '/api/v1/auth/login' && req.post?
end

# 2. Generic API traffic: 100 requests/minute per IP
Rack::Attack.throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/')
end

# 3. Block obvious scrapers (curl, wget, python-requests, …)
Rack::Attack.blocklist('suspicious user-agents') do |req|
  req.user_agent =~ /curl|wget|python-requests/i
end

# ───────────────────── Custom 429 response ──────────────────────
Rack::Attack.throttled_response = lambda do |env|
  data        = env['rack.attack.match_data'] || {}
  retry_after = data[:period] || 60

  [
    429,
    { 'Content-Type' => 'application/json',
      'Retry-After'  => retry_after.to_s },
    [ { error: 'Rate limit exceeded', retry_after: retry_after }.to_json ]
  ]
end
# -----------------------------------------