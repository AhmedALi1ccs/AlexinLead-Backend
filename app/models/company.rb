class Company < ApplicationRecord
  has_many :orders, foreign_key: 'third_party_provider_id'
  
  validates :name, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  
  scope :active, -> { where(is_active: true) }
  scope :top_performers, -> { order(total_revenue_generated: :desc) }
  
  def revenue_this_month
    orders.joins(:order_screen_requirements)
          .where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
          .where(payment_status: 'received')
          .sum(:total_amount) || 0
  end
  
  def update_order_stats!
    update!(
      total_orders_count: orders.count,
      total_revenue_generated: orders.where(payment_status: 'received').sum(:total_amount) || 0
    )
  end
end
