class User < ApplicationRecord
  has_secure_password
  has_one :employee, dependent: :destroy
  # Associations
  has_many :user_sessions, dependent: :destroy
  has_many :data_records, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :orders, dependent: :destroy  # ADD THIS LINE
  has_many :access_logs, dependent: :nullify
  has_many :data_permissions, dependent: :destroy
  has_many :shared_data_records, through: :data_permissions, source: :data_record
  has_many :expenses, dependent: :destroy  # ADD THIS LINE TOO
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :role, inclusion: { in: %w[admin user viewer] }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  
  # Callbacks
  before_save :normalize_email
  before_create :set_default_role
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :locked, -> { where('locked_until > ?', Time.current) }
  
  # Class methods
  def self.authenticate(email, password)
    user = find_by(email: email.downcase)
    return nil unless user&.is_active?
    return nil if user.account_locked?
    
    if user.authenticate(password)
      user.reset_failed_attempts!
      user.update_last_login!
      user
    else
      user.increment_failed_attempts!
      nil
    end
  end
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def admin?
    role == 'admin'
  end
  
  def can_edit?(resource)
    admin? || resource.user_id == id
  end
  
  def account_locked?
    locked_until.present? && locked_until > Time.current
  end
  
  def increment_failed_attempts!
    increment!(:failed_login_attempts)
    lock_account! if failed_login_attempts >= 5
  end
  
  def reset_failed_attempts!
    update!(failed_login_attempts: 0, locked_until: nil) if failed_login_attempts > 0
  end
  
  def update_last_login!
    update!(last_login_at: Time.current)
  end
  
  def lock_account!
    update!(locked_until: 30.minutes.from_now)
  end
  
  def generate_session_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless UserSession.exists?(session_token: token)
    end
  end
  
  def create_session!(ip_address: nil, user_agent: nil)
    # Clean up old sessions
    user_sessions.where('expires_at < ?', Time.current).destroy_all
    
    # Create new session
    user_sessions.create!(
      session_token: generate_session_token,
      ip_address: ip_address,
      user_agent: user_agent,
      expires_at: 24.hours.from_now
    )
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
  end
  
  def set_default_role
    self.role ||= 'user'
  end
end
