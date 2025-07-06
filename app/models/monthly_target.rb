class MonthlyTarget < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true, numericality: { greater_than: 2020 }
  validates :gross_earnings_target, presence: true, numericality: { greater_than: 0 }
  validates :month, uniqueness: { scope: :year }
  
  scope :for_date, ->(date) { where(year: date.year, month: date.month) }
  scope :current_month, -> { for_date(Date.current) }
  
  def self.for_current_month
    current_month.first
  end
  
  def self.get_or_create_for_month(month, year, user)
    find_or_create_by(month: month, year: year) do |target|
      target.gross_earnings_target = 50000 # Default target
      target.created_by = user
    end
  end
  
  def break_even_point
    estimated_fixed_expenses + estimated_variable_expenses
  end
  
  def progress_percentage(actual_revenue)
    return 0 if gross_earnings_target == 0
    ((actual_revenue / gross_earnings_target) * 100).round(2)
  end
  
  def break_even_achieved?(actual_revenue, actual_expenses)
    actual_revenue >= actual_expenses
  end
  
  def target_achieved?(actual_revenue)
    actual_revenue >= gross_earnings_target
  end
end
