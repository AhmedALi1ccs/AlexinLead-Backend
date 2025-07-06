class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :recurring_expense, optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  
  validates :expense_type, inclusion: { in: %w[labor transportation lunch others] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  
  # Contractor validations
  validates :hours_worked, :hourly_rate, presence: true, if: :hourly_contractor?
  validates :contractor_type, inclusion: { in: %w[salary hourly] }, allow_nil: true
  
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :by_type, ->(type) { where(expense_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :current_month, -> { where(expense_date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :for_month, ->(month, year) { where(expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month) }
  scope :recurring, -> { where.not(recurring_expense_id: nil) }
  scope :one_time, -> { where(recurring_expense_id: nil) }
  
  before_save :calculate_amount_if_hourly
  before_save :set_approved_at
  
  def self.total_for_month(month, year)
    approved.for_month(month, year).sum(:amount) || 0
  end
  
  def self.by_type_for_month(expense_type, month, year)
    approved.by_type(expense_type).for_month(month, year).sum(:amount) || 0
  end
  
  def self.generate_recurring_expenses_for_month(month, year)
    RecurringExpense.generate_monthly_expenses_for(month, year)
  end
  
  def hourly_contractor?
    contractor_type == 'hourly'
  end
  
  def auto_generated?
    recurring_expense_id.present?
  end
  
  def approve!(user)
    update!(status: 'approved', approved_by: user, approved_at: Time.current)
  end
  
  def reject!(user)
    update!(status: 'rejected', approved_by: user, approved_at: Time.current)
  end
  
  private
  
  def calculate_amount_if_hourly
    if hourly_contractor? && hours_worked.present? && hourly_rate.present?
      self.amount = hours_worked * hourly_rate
    end
  end
  
  def set_approved_at
    if status_changed? && status == 'approved' && approved_at.blank?
      self.approved_at = Time.current
    end
  end
end
