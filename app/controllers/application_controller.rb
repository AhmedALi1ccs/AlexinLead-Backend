class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  before_action :authenticate_request
  before_action :log_request
  
  private
  
  def authenticate_request
    return if @skip_authentication
    
    @current_user_session = UserSession.find_by_token(session_token)
    
    if @current_user_session&.expired?
      @current_user_session.destroy
      @current_user_session = nil
    end
    
    unless @current_user_session
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    
    @current_user = @current_user_session.user
    @current_user_session.extend_session!
  end
  
  def current_user
    @current_user
  end
  
  def current_user_session
    @current_user_session
  end
  
  def session_token
    request.headers['Authorization']&.split(' ')&.last ||
    cookies[:session_token]
  end
  
  def log_request
    return unless @current_user
    
    AccessLog.log_access(
      user: @current_user,
      action: action_name,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      success: true
    )
  rescue => e
    Rails.logger.error "Failed to log access: #{e.message}"
  end
  
  def log_failed_access(action, error_message = nil)
    AccessLog.log_access(
      user: @current_user,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      success: false,
      error_message: error_message
    )
  rescue => e
    Rails.logger.error "Failed to log failed access: #{e.message}"
  end
  
  def authorize_admin!
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end
  
  def skip_authentication
    @skip_authentication = true
  end
end