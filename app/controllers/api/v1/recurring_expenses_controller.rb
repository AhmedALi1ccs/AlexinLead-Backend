class Api::V1::RecurringExpensesController < ApplicationController
  before_action :authorize_admin!
  before_action :set_recurring_expense, only: [:show, :update, :destroy, :generate_expenses]
  
  def index
    @recurring_expenses = RecurringExpense.includes(:created_by).order(:name)
    
    # Filters
    @recurring_expenses = @recurring_expenses.where(is_active: params[:active]) if params[:active].present?
    @recurring_expenses = @recurring_expenses.for_type(params[:expense_type]) if params[:expense_type].present?
    @recurring_expenses = @recurring_expenses.where(frequency: params[:frequency]) if params[:frequency].present?
    
    render json: {
      recurring_expenses: @recurring_expenses.map { |re| serialize_recurring_expense(re) },
      summary: {
        total_active: RecurringExpense.active.count,
        monthly_total: RecurringExpense.active.monthly.sum(:amount),
        expense_types: RecurringExpense.distinct.pluck(:expense_type).sort,
        frequencies: RecurringExpense.distinct.pluck(:frequency).sort
      }
    }
  end
  
  def show
    render json: {
      recurring_expense: serialize_recurring_expense(@recurring_expense, include_details: true),
      generated_expenses: @recurring_expense.expenses.order(expense_date: :desc).limit(10).map { |e| serialize_expense(e) }
    }
  end
  
  def create
    @recurring_expense = RecurringExpense.new(recurring_expense_params)
    @recurring_expense.created_by = current_user
    
    if @recurring_expense.save
      render json: {
        message: 'Recurring expense created successfully',
        recurring_expense: serialize_recurring_expense(@recurring_expense, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create recurring expense',
        errors: @recurring_expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @recurring_expense.update(recurring_expense_params)
      render json: {
        message: 'Recurring expense updated successfully',
        recurring_expense: serialize_recurring_expense(@recurring_expense, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update recurring expense',
        errors: @recurring_expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @recurring_expense.update!(is_active: false)
    render json: { message: 'Recurring expense deactivated successfully' }
  end
  
  def generate_expenses
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    
    begin
      @recurring_expense.generate_expenses_for_month(month, year)
      
      render json: {
        message: "Expenses generated for #{Date::MONTHNAMES[month]} #{year}",
        generated_count: @recurring_expense.expenses.for_month(month, year).count
      }
    rescue => e
      render json: {
        error: 'Failed to generate expenses',
        message: e.message
      }, status: :unprocessable_entity
    end
  end
  
  def generate_all_for_month
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    
    begin
      RecurringExpense.generate_monthly_expenses_for(month, year)
      
      total_generated = Expense.where(
        expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
      ).where.not(recurring_expense_id: nil).count
      
      render json: {
        message: "All recurring expenses generated for #{Date::MONTHNAMES[month]} #{year}",
        total_generated: total_generated
      }
    rescue => e
      render json: {
        error: 'Failed to generate recurring expenses',
        message: e.message
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_recurring_expense
    @recurring_expense = RecurringExpense.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recurring expense not found' }, status: :not_found
  end
  
  def recurring_expense_params
    params.require(:recurring_expense).permit(
      :name, :expense_type, :amount, :frequency, :start_date, :end_date, :description, :is_active
    )
  end
  
  def serialize_recurring_expense(recurring_expense, include_details: false)
    data = {
      id: recurring_expense.id,
      name: recurring_expense.name,
      expense_type: recurring_expense.expense_type,
      amount: recurring_expense.amount,
      frequency: recurring_expense.frequency,
      start_date: recurring_expense.start_date,
      end_date: recurring_expense.end_date,
      is_active: recurring_expense.is_active,
      description: recurring_expense.description,
      created_by: recurring_expense.created_by.full_name,
      next_expense_date: recurring_expense.next_expense_date
    }
    
    if include_details
      data.merge!({
        expenses_count: recurring_expense.expenses.count,
        total_generated_amount: recurring_expense.expenses.sum(:amount),
        created_at: recurring_expense.created_at,
        updated_at: recurring_expense.updated_at,
        last_generated: recurring_expense.expenses.order(:expense_date).last&.expense_date,
        monthly_impact: calculate_monthly_impact(recurring_expense)
      })
    end
    
    data
  end
  
  def serialize_expense(expense)
    {
      id: expense.id,
      amount: expense.amount,
      expense_date: expense.expense_date,
      description: expense.description,
      status: expense.status,
      created_at: expense.created_at
    }
  end
  
  def calculate_monthly_impact(recurring_expense)
    case recurring_expense.frequency
    when 'monthly'
      recurring_expense.amount
    when 'weekly'
      recurring_expense.amount * 4.33 # Average weeks per month
    when 'daily'
      recurring_expense.amount * 30.44 # Average days per month
    else
      0
    end
  end
end