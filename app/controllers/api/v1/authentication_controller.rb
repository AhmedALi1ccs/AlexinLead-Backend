class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :authenticate_request, only: [:login]
  
  def login
    @user = User.authenticate(login_params[:email], login_params[:password])
    
    if @user
      @session = @user.create_session!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      AccessLog.log_access(
        user: @user,
        action: 'login',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: true
      )
      
      set_session_cookie(@session.session_token)
      
      render json: {
        message: 'Login successful',
        user: UserSerializer.new(@user).serializable_hash[:data][:attributes],
        session_token: @session.session_token
      }, status: :ok
    else
      AccessLog.log_access(
        user: User.find_by(email: login_params[:email]&.downcase),
        action: 'login',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: false,
        error_message: 'Invalid credentials'
      )
      
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end
  
  def logout
    if current_user_session
      AccessLog.log_access(
        user: current_user,
        action: 'logout',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: true
      )
      
      current_user_session.destroy
      clear_session_cookie
      
      render json: { message: 'Logout successful' }, status: :ok
    else
      render json: { error: 'No active session' }, status: :bad_request
    end
  end
  
  def refresh
    if current_user_session
      current_user_session.extend_session!
      set_session_cookie(current_user_session.session_token)
      
      render json: {
        message: 'Session refreshed',
        expires_at: current_user_session.expires_at
      }, status: :ok
    else
      render json: { error: 'No active session to refresh' }, status: :unauthorized
    end
  end
  
  def me
    if current_user
      render json: {
        user: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
      }, status: :ok
    else
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end
  end
  
  private
  
  def login_params
    params.require(:user).permit(:email, :password)
  end
  
  def set_session_cookie(token)
    cookies[:session_token] = {
      value: token,
      expires: 24.hours.from_now,
      secure: Rails.env.production?,
      httponly: true,
      same_site: :strict
    }
  end
  
  def clear_session_cookie
    cookies.delete(:session_token)
  end
end