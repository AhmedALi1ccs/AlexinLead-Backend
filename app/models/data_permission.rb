class DataPermission < ApplicationRecord
  belongs_to :data_record
  belongs_to :user
  belongs_to :granted_by, class_name: 'User', optional: true
  
  validates :permission_type, inclusion: { in: %w[read write admin] }
  validates :user_id, uniqueness: { scope: :data_record_id }
  
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :by_permission, ->(type) { where(permission_type: type) }
  
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
  
  def can_read?
    %w[read write admin].include?(permission_type)
  end
  
  def can_write?
    %w[write admin].include?(permission_type)
  end
  
  def can_admin?
    permission_type == 'admin'
  end
end