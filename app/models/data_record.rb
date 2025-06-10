class DataRecord < ApplicationRecord
  belongs_to :user
  has_many :access_logs, dependent: :destroy
  has_many :data_permissions, dependent: :destroy
  has_many :shared_users, through: :data_permissions, source: :user
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :data_type, presence: true
  validates :access_level, inclusion: { in: %w[public shared private] }
  validates :status, inclusion: { in: %w[active archived deleted] }
  
  scope :active, -> { where(status: 'active') }
  scope :archived, -> { where(status: 'archived') }
  scope :deleted, -> { where(status: 'deleted') }
  scope :by_type, ->(type) { where(data_type: type) }
  scope :public_records, -> { where(access_level: 'public') }
  scope :shared_records, -> { where(access_level: 'shared') }
  scope :private_records, -> { where(access_level: 'private') }
  
  def accessible_by?(user)
    return true if self.user == user
    return true if access_level == 'public'
    return true if access_level == 'shared' && data_permissions.exists?(user: user)
    false
  end
  
  def can_edit?(user)
    return true if self.user == user
    return true if user.admin?
    return true if data_permissions.exists?(user: user, permission_type: ['write', 'admin'])
    false
  end
end