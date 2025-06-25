class Expense < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :user
  
  validates :expense_type, inclusion: { in: %w[wages transportation additions] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  
  scope :by_type, ->(type) { where(expense_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :current_month, -> { where(expense_date: Time.current.beginning_of_month..Time.current.end_of_month) }
  
  def self.total_for_month(month = Time.current.month, year = Time.current.year)
    where(expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month)
      .sum(:amount)
  end
  
  def self.by_type_for_month(expense_type, month = Time.current.month, year = Time.current.year)
    by_type(expense_type)
      .where(expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month)
      .sum(:amount)
  end
end
