class OrderEquipmentAssignment < ApplicationRecord
  belongs_to :order
  belongs_to :equipment
  
  validates :assigned_at, presence: true
  validates :assignment_status, inclusion: { in: %w[assigned returned damaged lost] }
  
  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  
  def duration_days
    return 0 unless assigned_at
    end_time = returned_at || Time.current
    ((end_time - assigned_at) / 1.day).ceil
  end
  
  def active?
    returned_at.nil?
  end
  
  def return_equipment!(status = 'returned', notes = nil)
    transaction do
      update!(
        returned_at: Time.current,
        assignment_status: status,
        return_notes: notes
      )
      
      equipment.return_from_order!(status)
    end
  end
end
