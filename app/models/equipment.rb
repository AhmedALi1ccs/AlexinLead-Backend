# Replace your entire app/models/equipment.rb file with this:

class Equipment < ApplicationRecord
  has_many :order_equipment_assignments, dependent: :destroy
  has_many :orders, through: :order_equipment_assignments
  
  validates :equipment_type, inclusion: { in: %w[laptop video_processor cable] }
  validates :status, inclusion: { in: %w[available assigned maintenance damaged retired] }
  validates :serial_number, uniqueness: true, allow_blank: true
  
  scope :available, -> { where(status: 'available') }
  scope :assigned, -> { where(status: 'assigned') }
  scope :laptops, -> { where(equipment_type: 'laptop') }
  scope :video_processors, -> { where(equipment_type: 'video_processor') }
  scope :cables, -> { where(equipment_type: 'cable') }
  
  def available?
    status == 'available'
  end
  
  def assigned_to_order
    return nil unless status == 'assigned'
    order_equipment_assignments.where(returned_at: nil).first&.order
  end
  
  def assign_to_order!(order)
    return false unless available?
    
    transaction do
      update!(status: 'assigned')
      order_equipment_assignments.create!(
        order: order,
        assigned_at: Time.current,
        assignment_status: 'assigned'
      )
    end
  end
  
  def return_from_order!(return_status = 'returned')
    return false unless assigned?
    
    transaction do
      assignment = order_equipment_assignments.where(returned_at: nil).first
      assignment&.update!(
        returned_at: Time.current,
        assignment_status: return_status
      )
      
      new_equipment_status = return_status == 'returned' ? 'available' : return_status
      update!(status: new_equipment_status)
    end
  end
  
  # Date-based availability checking
  def self.available_for_dates(equipment_type, start_date, end_date)
    # Find equipment that's reserved for overlapping dates
    reserved_equipment_ids = joins(:order_equipment_assignments => :order)
                            .where(equipment_type: equipment_type)
                            .where(orders: { order_status: 'confirmed' })
                            .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
                            .where(order_equipment_assignments: { assignment_status: 'assigned', returned_at: nil })
                            .distinct.pluck(:id)
    
    # Count equipment that's available and not reserved for these dates
    where(equipment_type: equipment_type, status: 'available')
      .where.not(id: reserved_equipment_ids)
      .count
  end

  # Calculate availability for specific dates
  def self.availability_for_dates(start_date, end_date)
    {
      laptops: {
        total: laptops.where(status: ['available', 'assigned']).count,
        available: available_for_dates('laptop', start_date, end_date)
      },
      video_processors: {
        total: video_processors.where(status: ['available', 'assigned']).count,
        available: available_for_dates('video_processor', start_date, end_date)
      }
    }
  end
  
  private
  
  def assigned?
    status == 'assigned'
  end
end