class Item < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, length: { maximum: 255 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active disposed maintenance reserved] }
  validates :disposal_reason, presence: true, if: -> { status == 'disposed' }
  
  scope :active, -> { where(status: 'active') }
  scope :disposed, -> { where(status: 'disposed') }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_location, ->(location) { where(location: location) if location.present? }
  
  def dispose!(reason, disposed_by_user)
    update!(
      status: 'disposed',
      disposed_at: Time.current,
      disposal_reason: reason
    )
  end
  
  def total_value
    (value || 0) * quantity
  end
  
  def can_be_disposed?
    status == 'active'
  end
end
