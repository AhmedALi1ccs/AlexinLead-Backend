class OrderScreenRequirement < ApplicationRecord
  self.table_name = 'order_screen_requirements'
  
  belongs_to :order
  belongs_to :screen_inventory
  
  validates :sqm_required, presence: true, numericality: { greater_than: 0 }
  validates :dimensions_rows, :dimensions_columns, 
            numericality: { greater_than: 0 }, 
            allow_nil: true
  validate :sufficient_inventory_available, on: :create
  validate :dimensions_match_sqm, if: -> { dimensions_rows.present? && dimensions_columns.present? }
  
  scope :reserved, -> { where.not(reserved_at: nil) }
  scope :active, -> { where(released_at: nil) }
  
  def reserved?
    reserved_at.present?
  end
  
  def released?
    released_at.present?
  end
  
  def calculated_sqm
    return nil unless dimensions_rows.present? && dimensions_columns.present?
    
    # Calculate based on screen pixel pitch and standard panel sizes
    pixel_pitch = screen_inventory.pixel_pitch.to_f
    
    # Standard LED panel size calculations (typical 500x500mm panels)
    panel_width = 0.5  # 500mm = 0.5m
    panel_height = 0.5 # 500mm = 0.5m
    
    total_width = dimensions_columns * panel_width
    total_height = dimensions_rows * panel_height
    
    (total_width * total_height).round(2)
  end
  
  private
  
  def sufficient_inventory_available
    return unless screen_inventory && sqm_required && order
    
    unless screen_inventory.available_for_dates?(order.start_date, order.end_date, sqm_required)
      errors.add(:sqm_required, "exceeds available inventory for this time period")
    end
  end
  
  def dimensions_match_sqm
    calculated = calculated_sqm
    return unless calculated
    
    # Allow 5% tolerance for rounding
    tolerance = 0.05
    if (sqm_required - calculated).abs > (calculated * tolerance)
      errors.add(:sqm_required, "doesn't match calculated area from dimensions (#{calculated}m²)")
    end
  end
end
