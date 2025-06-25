class ScreenInventory < ApplicationRecord
  self.table_name = 'screen_inventory'  # Tell Rails to use singular table name
  
  has_many :order_screen_requirements, dependent: :destroy
  has_many :orders, through: :order_screen_requirements
  has_many :screen_maintenances, dependent: :destroy
  validates :screen_type, presence: true, uniqueness: true
  validates :pixel_pitch, presence: true
  validates :total_sqm_owned,presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :by_pixel_pitch, ->(pitch) { where(pixel_pitch: pitch) }
  def maintenance_sqm_between(start_date, end_date)
    screen_maintenances
      .where('maintenance_start_date <= ? AND maintenance_end_date >= ?', end_date, start_date)
      .sum(:sqm)
  end
  def available_for_dates?(start_date, end_date, required_sqm)
    reserved_sqm = order_screen_requirements
      .joins(:order)
      .where(orders: { order_status: %w[confirmed in_progress] })
      .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
      .sum(:sqm_required)

    maint_sqm = maintenance_sqm_between(start_date, end_date)
    (total_sqm_owned - reserved_sqm - maint_sqm) >= required_sqm.to_f
  end
  


  
  private
  
  
end
