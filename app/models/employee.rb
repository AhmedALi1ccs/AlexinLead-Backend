class Employee < ApplicationRecord
  self.primary_key = 'id'
  has_many :installing_orders, class_name: 'Order', foreign_key: 'installing_assignee_id'
  has_many :disassembling_orders, class_name: 'Order', foreign_key: 'disassemble_assignee_id'
  
  validates :first_name, :last_name, :email, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :hourly_rate, numericality: { greater_than: 0 }, allow_nil: true
  
  scope :active, -> { where(is_active: true) }
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def available_for_date_range?(start_date, end_date)
    conflicting_installs = installing_orders.where(
      '(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?)',
      start_date, start_date, end_date, end_date
    ).where.not(order_status: ['completed', 'cancelled']).exists?
    
    conflicting_disassembles = disassembling_orders.where(
      'end_date BETWEEN ? AND ?', start_date, end_date
    ).where.not(order_status: ['completed', 'cancelled']).exists?
    
    !conflicting_installs && !conflicting_disassembles
  end
end
