class Api::V1::ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_edit_access, only: [:update, :destroy]
  before_action :authorize_admin!, only: [:approve, :reject]
  
  def index
    @expenses = Expense.includes(:user, :order, :recurring_expense, :approved_by).order(expense_date: :desc)
    
    # Filters
    @expenses = @expenses.by_type(params[:expense_type]) if params[:expense_type].present?
    @expenses = @expenses.where(order_id: params[:order_id]) if params[:order_id].present?
    @expenses = @expenses.where(status: params[:status]) if params[:status].present?
    @expenses = @expenses.where(contractor_type: params[:contractor_type]) if params[:contractor_type].present?
    
    # Filter by recurring vs one-time
    @expenses = @expenses.recurring if params[:recurring] == 'true'
    @expenses = @expenses.one_time if params[:recurring] == 'false'
    
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @expenses = @expenses.by_date_range(
        Date.parse(params[:start_date]), 
        Date.parse(params[:end_date])
      )
    end
    
    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    offset = (page - 1) * per_page
    
    total_count = @expenses.count
    @expenses = @expenses.limit(per_page).offset(offset)
    
    render json: {
      expenses: @expenses.map { |expense| serialize_expense(expense) },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      },
      summary: expense_summary,
      filters: {
        expense_types: Expense.distinct.pluck(:expense_type).compact.sort,
        contractor_types: Expense.distinct.pluck(:contractor_type).compact.sort,
        statuses: %w[pending approved rejected]
      }
    }
  end
  
  def show
    render json: {
      expense: serialize_expense(@expense, include_details: true)
    }
  end
  
  def create
    @expense = current_user.expenses.build(expense_params)
    
    if @expense.save
      render json: {
        message: 'Expense recorded successfully',
        expense: serialize_expense(@expense, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to record expense',
        errors: @expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @expense.update(expense_params)
      render json: {
        message: 'Expense updated successfully',
        expense: serialize_expense(@expense, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update expense',
        errors: @expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @expense.destroy
    render json: { message: 'Expense deleted successfully' }
  end
  
  def approve
    @expense.approve!(current_user)
    render json: {
      message: 'Expense approved successfully',
      expense: serialize_expense(@expense, include_details: true)
    }
  rescue => e
    render json: {
      error: 'Failed to approve expense',
      message: e.message
    }, status: :unprocessable_entity
  end
  
  def reject
    @expense.reject!(current_user)
    render json: {
      message: 'Expense rejected successfully',
      expense: serialize_expense(@expense, include_details: true)
    }
  rescue => e
    render json: {
      error: 'Failed to reject expense',
      message: e.message
    }, status: :unprocessable_entity
  end
  
  def summary
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    
    render json: {
      month: month,
      year: year,
      total_expenses: Expense.total_for_month(month, year),
      by_type: {
        labor: Expense.by_type_for_month('labor', month, year),
        transportation: Expense.by_type_for_month('transportation', month, year),
        lunch: Expense.by_type_for_month('lunch', month, year),
        others: Expense.by_type_for_month('others', month, year)
      },
      by_status: {
        approved: Expense.approved.for_month(month, year).sum(:amount),
        pending: Expense.pending.for_month(month, year).sum(:amount),
        rejected: Expense.where(status: 'rejected').for_month(month, year).sum(:amount)
      },
      contractor_summary: {
        hourly_total: Expense.approved.where(contractor_type: 'hourly').for_month(month, year).sum(:amount),
        salary_total: Expense.approved.where(contractor_type: 'salary').for_month(month, year).sum(:amount),
        total_hours: Expense.approved.where(contractor_type: 'hourly').for_month(month, year).sum(:hours_worked) || 0
      },
      recent_expenses: Expense.approved.where(
        expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
      ).order(expense_date: :desc).limit(10).map { |expense| serialize_expense(expense) }
    }
  end
  
  def pending_approval
    @pending_expenses = Expense.pending.includes(:user, :order).order(expense_date: :desc)
    
    render json: {
      pending_expenses: @pending_expenses.map { |expense| serialize_expense(expense) },
      total_pending_amount: @pending_expenses.sum(:amount),
      count: @pending_expenses.count
    }
  end
  
  private
  
  def set_expense
    @expense = Expense.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Expense not found' }, status: :not_found
  end
  
  def check_edit_access
    unless @expense.user == current_user || current_user.admin?
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def expense_params
    permitted_params = [
      :order_id, :expense_type, :amount, :expense_date, :description,
      :contractor_type, :hours_worked, :hourly_rate
    ]
    
    # Only admins can set status and approval fields
    if current_user.admin?
      permitted_params += [:status, :approved_by_id, :approved_at]
    end
    
    params.require(:expense).permit(permitted_params)
  end
  
  def serialize_expense(expense, include_details: false)
    data = {
      id: expense.id,
      expense_type: expense.expense_type,
      amount: expense.amount,
      expense_date: expense.expense_date,
      description: expense.description,
      status: expense.status,
      contractor_type: expense.contractor_type,
      hours_worked: expense.hours_worked,
      hourly_rate: expense.hourly_rate,
      recorded_by: expense.user.full_name,
      auto_generated: expense.auto_generated?
    }
    
    if expense.order
      data[:order] = {
        id: expense.order.id,
        order_id: expense.order.order_id,
        location_name: expense.order.location_name
      }
    end
    
    if expense.recurring_expense
      data[:recurring_expense] = {
        id: expense.recurring_expense.id,
        name: expense.recurring_expense.name
      }
    end
    
    if expense.approved_by
      data[:approved_by] = expense.approved_by.full_name
      data[:approved_at] = expense.approved_at
    end
    
    if include_details
      data.merge!({
        created_at: expense.created_at,
        updated_at: expense.updated_at
      })
    end
    
    data
  end
  
  def expense_summary
    current_month_expenses = Expense.current_month
    {
      total_this_month: current_month_expenses.approved.sum(:amount),
      pending_approval: current_month_expenses.pending.sum(:amount),
      count_this_month: current_month_expenses.approved.count,
      pending_count: current_month_expenses.pending.count,
      by_type_this_month: {
        labor: current_month_expenses.approved.by_type('labor').sum(:amount),
        transportation: current_month_expenses.approved.by_type('transportation').sum(:amount),
        lunch: current_month_expenses.approved.by_type('lunch').sum(:amount),
        others: current_month_expenses.approved.by_type('others').sum(:amount)
      },
      expense_types: Expense.distinct.pluck(:expense_type).compact.sort
    }
  end
end
