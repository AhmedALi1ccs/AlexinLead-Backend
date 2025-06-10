class AccessLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :data_record, optional: true
  
  validates :action, presence: true
  validates :action, inclusion: { in: %w[create read update delete download login logout dispose] }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  
  def self.log_access(user:, action:, data_record: nil, ip_address: nil, user_agent: nil, success: true, error_message: nil)
    # For now, we'll only log if data_record is actually a DataRecord or nil
    # Items will be logged differently or we can skip logging for items
    if data_record.nil? || data_record.is_a?(DataRecord)
      create!(
        user: user,
        data_record: data_record,
        action: action,
        ip_address: ip_address,
        user_agent: user_agent,
        success: success,
        error_message: error_message
      )
    else
      # For Items, create a log without the data_record association
      create!(
        user: user,
        data_record: nil,  # Set to nil for Items
        action: action,
        ip_address: ip_address,
        user_agent: user_agent,
        success: success,
        error_message: error_message
      )
    end
  rescue => e
    Rails.logger.error "Failed to create access log: #{e.message}"
  end
end
