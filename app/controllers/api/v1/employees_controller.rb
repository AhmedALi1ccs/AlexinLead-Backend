class Api::V1::EmployeesController < ApplicationController
  before_action :set_employee, only: [:show, :update, :destroy]
  before_action :authorize_admin!, except: [:index, :show]
  
  def index
    @employees = Employee.all.order(:first_name, :last_name)
    
    # Filters
    @employees = @employees.active if params[:active_only] == 'true'
    @employees = @employees.where('first_name ILIKE ? OR last_name ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    
    render json: {
      employees: @employees.map { |employee| serialize_employee(employee) }
    }
  end
  
  def show
    render json: {
      employee: serialize_employee(@employee, include_details: true),
      stats: employee_stats(@employee)
    }
  end
  
  def create
    @employee = Employee.new(employee_params)
    
    if @employee.save
      render json: {
        message: 'Employee created successfully',
        employee: serialize_employee(@employee, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create employee',
        errors: @employee.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @employee.update(employee_params)
      render json: {
        message: 'Employee updated successfully',
        employee: serialize_employee(@employee, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update employee',
        errors: @employee.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @employee.update!(is_active: false)
    render json: { message: 'Employee deactivated successfully' }
  end
  
  def availability
    start_date = Date.parse(params[:start_date]) rescue Date.current
    end_date = Date.parse(params[:end_date]) rescue Date.current + 7.days
    
    available_employees = Employee.active.select do |employee|
      employee.available_for_date_range?(start_date, end_date)
    end
    
    render json: {
      available_employees: available_employees.map { |employee| serialize_employee(employee) },
      date_range: { start_date: start_date, end_date: end_date }
    }
  end
  
  private
  
  def set_employee
    @employee = Employee.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Employee not found' }, status: :not_found
  end
  
  def employee_params
    params.require(:employee).permit(
      :first_name, :last_name, :email, :phone, :role, :is_active, :hourly_rate
    )
  end
  
  def serialize_employee(employee, include_details: false)
    data = {
      id: employee.id,
      full_name: employee.full_name,
      email: employee.email,
      role: employee.role,
      is_active: employee.is_active
    }
    
    if include_details
      data.merge!({
        first_name: employee.first_name,
        last_name: employee.last_name,
        phone: employee.phone,
        hourly_rate: employee.hourly_rate,
        created_at: employee.created_at
      })
    end
    
    data
  end
  
  def employee_stats(employee)
    {
      total_installations: employee.installing_orders.count,
      total_disassembles: employee.disassembling_orders.count,
      active_orders: employee.installing_orders.active.count + employee.disassembling_orders.active.count,
      orders_this_month: employee.installing_orders.current_month.count + employee.disassembling_orders.current_month.count
    }
  end
end
