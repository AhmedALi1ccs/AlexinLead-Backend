class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy, :activate, :deactivate, :reset_password]
  before_action :authorize_admin!, except: [:show, :update]
  before_action :check_self_or_admin, only: [:show, :update]
  
  def index
    @users = User.all.order(:created_at)
    
    # Filters
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where(is_active: params[:active] == 'true') if params[:active].present?
    @users = @users.where('first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?', 
                         "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    
    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    offset = (page - 1) * per_page
    
    total_count = @users.count
    @users = @users.limit(per_page).offset(offset)
    
    render json: {
      users: @users.map { |user| serialize_user(user) },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      },
      stats: {
        total_users: User.count,
        active_users: User.where(is_active: true).count,
        admin_users: User.where(role: 'admin').count,
        employee_users: User.where(role: 'user').count
      }
    }
  end
  
  def show
    render json: { user: serialize_user(@user, include_details: true) }
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      AccessLog.log_access(
        user: current_user,
        action: 'create_user',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: true
      )
      
      render json: {
        message: 'User created successfully',
        user: serialize_user(@user, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def create_employee
    ActiveRecord::Base.transaction do
      # Generate a temporary password
      temp_password = SecureRandom.hex(8)
      
      # Create the user account
      @user = User.new(
        first_name: employee_params[:first_name],
        last_name: employee_params[:last_name],
        email: employee_params[:email],
        role: employee_params[:role] || 'user',
        password: temp_password,
        is_active: true
      )
      
      if @user.save
        # Create corresponding employee record
        @employee = Employee.create!(
          id: @user.id,
          first_name: employee_params[:first_name],
          last_name: employee_params[:last_name],
          email: employee_params[:email],
          phone: employee_params[:phone],
          role: employee_params[:job_role] || 'technician',
          hourly_rate: employee_params[:hourly_rate],
          contract_type: employee_params[:contract_type], # 👈 added
          is_active: true
        )

        
        AccessLog.log_access(
          user: current_user,
          action: 'create_employee',
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          success: true
        )
        
        render json: {
          message: 'Employee and user account created successfully',
          user: serialize_user(@user, include_details: true),
          employee: serialize_employee(@employee),
          temporary_password: temp_password
        }, status: :created
      else
        render json: {
          error: 'Failed to create employee',
          errors: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue => e
    render json: {
      error: 'Failed to create employee',
      message: e.message
    }, status: :internal_server_error
  end
  
  def update
    if @user.update(user_update_params)
      if params[:user][:contract_type].present?
        @user.employee&.update(contract_type: params[:user][:contract_type])
      end
      AccessLog.log_access(
        user: current_user,
        action: 'update_user',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: true
      )
      
      render json: {
        message: 'User updated successfully',
        user: serialize_user(@user, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @user.update!(is_active: false)
    
    AccessLog.log_access(
      user: current_user,
      action: 'deactivate_user',
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      success: true
    )
    
    render json: { message: 'User deactivated successfully' }
  end
  
  def activate
    @user.update!(is_active: true)
    render json: { message: 'User activated successfully' }
  end
  
  def deactivate
    @user.update!(is_active: false)
    render json: { message: 'User deactivated successfully' }
  end

  def reset_password
    new_password = SecureRandom.hex(8)
    
    if @user.update(password: new_password)
      AccessLog.log_access(
        user: current_user,
        action: 'reset_user_password',
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        success: true
      )
      
      render json: {
        message: 'Password reset successfully',
        new_password: new_password
      }
    else
      render json: {
        error: 'Failed to reset password',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
  
  def check_self_or_admin
    unless @user == current_user || current_user.admin?
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :role)
  end

  def employee_params
    params.require(:employee).permit(:first_name, :last_name, :email, :phone, :role, :job_role, :hourly_rate, :contract_type)
  end
  
  def user_update_params
    allowed_params = [:first_name, :last_name, :email]
    allowed_params += [:role, :is_active] if current_user.admin?
    params.require(:user).permit(allowed_params)
  end
  
  def serialize_user(user, include_details: false)
    data = {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      email: user.email,
      role: user.role,
      is_active: user.is_active,
      created_at: user.created_at
    }
    
    if include_details
      data.merge!({
        last_login_at: user.last_login_at,
        failed_login_attempts: user.failed_login_attempts,
        locked_until: user.locked_until,
        orders_count: user.orders.count,
        expenses_count: user.expenses.count,
        contract_type: user.employee&.contract_type
      })
    end
    
    data
  end

  def serialize_employee(employee)
    {
      id: employee.id,
      first_name: employee.first_name,
      last_name: employee.last_name,
      full_name: employee.full_name,
      email: employee.email,
      phone: employee.phone,
      role: employee.role,
      hourly_rate: employee.hourly_rate,
      is_active: employee.is_active
    }
  end
end