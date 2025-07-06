class Api::V1::MonthlyTargetsController < ApplicationController
  before_action :authorize_admin!
  before_action :set_monthly_target, only: [:show, :update, :destroy]
  
  def index
    year = params[:year]&.to_i || Time.current.year
    @monthly_targets = MonthlyTarget.where(year: year).includes(:created_by).order(:month)
    
    render json: {
      monthly_targets: @monthly_targets.map { |target| serialize_monthly_target_with_progress(target) },
      year: year,
      summary: {
        total_targets: @monthly_targets.count,
        average_target: @monthly_targets.average(:gross_earnings_target)&.round(2) || 0,
        total_annual_target: @monthly_targets.sum(:gross_earnings_target)
      }
    }
  end
  
  def show
    render json: {
      monthly_target: serialize_monthly_target_with_progress(@monthly_target)
    }
  end
  
  def create
    @monthly_target = MonthlyTarget.new(monthly_target_params)
    @monthly_target.created_by = current_user
    
    if @monthly_target.save
      render json: {
        message: 'Monthly target created successfully',
        monthly_target: serialize_monthly_target_with_progress(@monthly_target)
      }, status: :created
    else
      render json: {
        error: 'Failed to create monthly target',
        errors: @monthly_target.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @monthly_target.update(monthly_target_params)
      render json: {
        message: 'Monthly target updated successfully',
        monthly_target: serialize_monthly_target_with_progress(@monthly_target)
      }
    else
      render json: {
        error: 'Failed to update monthly target',
        errors: @monthly_target.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @monthly_target.destroy
    render json: { message: 'Monthly target deleted successfully' }
  end
  
  def current_month
    target = MonthlyTarget.for_current_month
    if target
      render json: { monthly_target: serialize_monthly_target_with_progress(target) }
    else
      render json: { monthly_target: nil }
    end
  end
  
  private
  
  def set_monthly_target
    @monthly_target = MonthlyTarget.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Monthly target not found' }, status: :not_found
  end
  
  def monthly_target_params
    params.require(:monthly_target).permit(:month, :year, :gross_earnings_target, :estimated_fixed_expenses, :estimated_variable_expenses, :notes)
  end
  
  def serialize_monthly_target_with_progress(target)
    # Calculate actual performance for the target month
    date_range = Date.new(target.year, target.month).beginning_of_month..Date.new(target.year, target.month).end_of_month
    actual_revenue = Order.where(created_at: date_range, payment_status: 'received').sum(:total_amount) || 0
    actual_expenses = Expense.approved.where(expense_date: date_range).sum(:amount) || 0
    
    {
      id: target.id,
      month: target.month,
      month_name: Date::MONTHNAMES[target.month],
      year: target.year,
      gross_earnings_target: target.gross_earnings_target,
      estimated_fixed_expenses: target.estimated_fixed_expenses,
      estimated_variable_expenses: target.estimated_variable_expenses,
      break_even_point: target.break_even_point,
      notes: target.notes,
      created_by: target.created_by.full_name,
      created_at: target.created_at,
      
      # Progress data
      actual_revenue: actual_revenue,
      actual_expenses: actual_expenses,
      net_income: actual_revenue - actual_expenses,
      progress_percentage: target.progress_percentage(actual_revenue),
      break_even_achieved: target.break_even_achieved?(actual_revenue, actual_expenses),
      target_achieved: target.target_achieved?(actual_revenue),
      
      # Status indicators
      status: determine_target_status(target, actual_revenue, actual_expenses),
      variance: actual_revenue - target.gross_earnings_target
    }
  end
  
  def determine_target_status(target, actual_revenue, actual_expenses)
    if target.target_achieved?(actual_revenue)
      'achieved'
    elsif target.break_even_achieved?(actual_revenue, actual_expenses)
      'break_even'
    elsif Date.current > Date.new(target.year, target.month).end_of_month
      'missed'
    else
      'in_progress'
    end
  end
end
