class UserSession < ApplicationRecord
  belongs_to :user
  
  validates :session_token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  
  def self.find_by_token(token)
    active.find_by(session_token: token)
  end
  
  def expired?
    expires_at <= Time.current
  end
  
  def extend_session!
    update!(expires_at: 24.hours.from_now)
  end
end