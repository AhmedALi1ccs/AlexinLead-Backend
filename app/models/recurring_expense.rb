class RecurringExpense < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  has_many :expenses, dependent: :nullify
  
  validates :name, presence: true
  validates :expense_type, inclusion: { in: %w[labor transportation lunch others] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, inclusion: { in: %w[monthly weekly daily] }
  validates :start_date, presence: true
  
  scope :active, -> { where(is_active: true) }
  scope :monthly, -> { where(frequency: 'monthly') }
  scope :for_type, ->(type) { where(expense_type: type) }
  
  def self.generate_monthly_expenses_for(month, year)
    active.each do |recurring_expense|
      recurring_expense.generate_expenses_for_month(month, year)
    end
  end
  
  def generate_expenses_for_month(month, year)
    return unless active_for_month?(month, year)
    
    case frequency
    when 'monthly'
      generate_monthly_expense(month, year)
    when 'weekly'
      generate_weekly_expenses(month, year)
    when 'daily'
      generate_daily_expenses(month, year)
    end
  end
  
  def next_expense_date
    last_expense = expenses.order(:expense_date).last
    base_date = last_expense&.expense_date || start_date
    
    case frequency
    when 'monthly'
      base_date + 1.month
    when 'weekly'
      base_date + 1.week
    when 'daily'
      base_date + 1.day
    end
  end
  
  private
  
  def active_for_month?(month, year)
    month_date = Date.new(year, month)
    start_date <= month_date.end_of_month && 
    (end_date.nil? || end_date >= month_date.beginning_of_month)
  end
  
  def generate_monthly_expense(month, year)
    # Generate on the same day of month as start_date
    expense_date = Date.new(year, month, [start_date.day, Date.new(year, month, -1).day].min)
    create_expense_if_not_exists(expense_date)
  end
  
  def generate_weekly_expenses(month, year)
    month_start = Date.new(year, month).beginning_of_month
    month_end = Date.new(year, month).end_of_month
    
    current_date = start_date
    while current_date <= month_end
      if current_date >= month_start
        create_expense_if_not_exists(current_date)
      end
      current_date += 1.week
    end
  end
  
  def generate_daily_expenses(month, year)
    month_start = Date.new(year, month).beginning_of_month
    month_end = Date.new(year, month).end_of_month
    
    (month_start..month_end).each do |date|
      create_expense_if_not_exists(date) if date >= start_date
    end
  end
  
  def create_expense_if_not_exists(expense_date)
    return if expenses.exists?(expense_date: expense_date)
    
    expenses.create!(
      user: created_by,
      expense_type: expense_type,
      amount: amount,
      expense_date: expense_date,
      description: "Auto-generated: #{name}",
      status: 'approved'
    )
  end
end
