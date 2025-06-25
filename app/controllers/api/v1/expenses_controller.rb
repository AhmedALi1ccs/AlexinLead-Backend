class Api::V1::ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :update, :destroy]
  before_action :check_edit_access, only: [:update, :destroy]
  
  def index
    @expenses = Expense.includes(:user, :order).order(expense_date: :desc)
    
    # Filters
    @expenses = @expenses.by_type(params[:expense_type]) if params[:expense_type].present?
    @expenses = @expenses.where(order_id: params[:order_id]) if params[:order_id].present?
    
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
      summary: expense_summary
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
  
  def summary
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    
    render json: {
      month: month,
      year: year,
      total_expenses: Expense.total_for_month(month, year),
      by_type: {
        wages: Expense.by_type_for_month('wages', month, year),
        transportation: Expense.by_type_for_month('transportation', month, year),
        additions: Expense.by_type_for_month('additions', month, year)
      },
      recent_expenses: Expense.where(
        expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
      ).order(expense_date: :desc).limit(10).map { |expense| serialize_expense(expense) }
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
    params.require(:expense).permit(
      :order_id, :expense_type, :amount, :expense_date, :description
    )
  end
  
  def serialize_expense(expense, include_details: false)
    data = {
      id: expense.id,
      expense_type: expense.expense_type,
      amount: expense.amount,
      expense_date: expense.expense_date,
      description: expense.description,
      recorded_by: expense.user.full_name
    }
    
    if expense.order
      data[:order] = {
        id: expense.order.id,
        location_name: expense.order.location_name
      }
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
      total_this_month: current_month_expenses.sum(:amount),
      count_this_month: current_month_expenses.count,
      by_type_this_month: {
        wages: current_month_expenses.by_type('wages').sum(:amount),
        transportation: current_month_expenses.by_type('transportation').sum(:amount),
        additions: current_month_expenses.by_type('additions').sum(:amount)
      },
      expense_types: Expense.distinct.pluck(:expense_type)
    }
  end
end
