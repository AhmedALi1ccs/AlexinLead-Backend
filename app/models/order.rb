class Order < ApplicationRecord
  belongs_to :user
  belongs_to :installing_assignee, class_name: 'Employee'
  belongs_to :disassemble_assignee, class_name: 'Employee'
  belongs_to :third_party_provider, class_name: 'Company', optional: true
  
  has_many :order_screen_requirements, dependent: :destroy
  has_many :screen_inventories, through: :order_screen_requirements
  has_many :order_equipment_assignments, dependent: :destroy
  has_many :equipment, through: :order_equipment_assignments
  has_many :expenses, dependent: :nullify
  
  validates :price_per_sqm, presence: true, numericality: { greater_than: 0 }
  validates :laptops_needed, :video_processors_needed,
            presence: true, numericality: { greater_than: 0 }
  validates :payment_status, inclusion: { in: %w[received not_received partial] }
  validates :order_status, inclusion: { in: %w[confirmed cancelled] }
  validates :start_date, :end_date, presence: true
  validates :order_id, presence: true, uniqueness: true
  validate :end_date_after_start_date
  validate :compatible_screen_types, if: -> { order_screen_requirements.any? }
  validate :sufficient_equipment_available, on: :create
  validate :has_screen_requirements, on: :create
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :payed,        numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_order_id, on: :create
  before_save :calculate_duration_days
  before_save :update_overdue_status
  after_create :reserve_inventory_and_equipment
  after_update :handle_status_changes
  
  scope :active, -> {
    today = Date.current
    where("DATE(start_date) <= ? AND DATE(end_date) >= ?", today, today)
  }
  scope :cancelled, -> { where(order_status: 'cancelled') }
  scope :paid, -> { where(payment_status: 'received') }
  scope :unpaid, -> { where(payment_status: ['not_received', 'partial']) }
  scope :partial_paid, -> { where(payment_status: 'partial') }
  scope :current_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :for_date, ->(date) { where('start_date <= ? AND end_date >= ?', date, date) }
  scope :overdue, -> { where('due_date < ? AND payment_status != ?', Date.current, 'received') }
  scope :due_soon, -> { where(due_date: Date.current..1.week.from_now) }
  
  def total_sqm_required
    order_screen_requirements.sum(:sqm_required)
  end
  
  def remaining
    total_amount - payed
  end
  
  def outstanding_amount
    total_amount - payed
  end

def unreserve_resources!
  transaction do
    # Unreserve screen requirements (set reserved_at to nil)
    order_screen_requirements.destroy_all

    # Return equipment and mark them as available (same as cancel! method)
    equipment.each do |eq| 
      eq.return_from_order! if eq.status == 'assigned' 
    end
    
    # Destroy all equipment assignments
    order_equipment_assignments.destroy_all
  end
rescue => e
  Rails.logger.error "Failed to unreserve resources for order #{order_id}: #{e.message}"
  raise e
end

  
  def days_overdue
    return 0 unless due_date && due_date < Date.current && payment_status != 'received'
    (Date.current - due_date).to_i
  end
  
  def overdue?
    due_date && due_date < Date.current && payment_status != 'received'
  end
  
  def payment_progress_percentage
    return 0 if total_amount == 0
    ((payed / total_amount) * 100).round(2)
  end
  
  def generate_invoice_number
    return if invoice_number.present?
    
    year = created_at.year
    month = created_at.strftime('%m')
    sequence = Order.where(
      created_at: created_at.beginning_of_month..created_at.end_of_month
    ).count + 1
    
    self.invoice_number = "INV-#{year}#{month}-#{sequence.to_s.rjust(4, '0')}"
  end
  
  def total_dimensions_summary
    requirements = order_screen_requirements.includes(:screen_inventory)
    summary = requirements.map do |req|
      if req.dimensions_rows && req.dimensions_columns
        "#{req.screen_inventory.screen_type}: #{req.dimensions_rows}×#{req.dimensions_columns}"
      else
        "#{req.screen_inventory.screen_type}: #{req.sqm_required}m²"
      end
    end
    summary.join(', ')
  end
  
  def is_active_today?
    order_status == 'confirmed' && 
    Date.current >= start_date.to_date && 
    Date.current <= end_date.to_date
  end

  def is_happening_today?
    is_active_today?
  end
  
  def revenue
    return 0 unless payment_status == 'received'
    total_amount || 0
  end
  
  def can_cancel?
    order_status == 'confirmed'
  end
  
  def cancel!
    return false unless can_cancel?
    
    transaction do
      # Release screen inventory
      order_screen_requirements.each do |req|
        unless req.screen_inventory.available_for_dates?(self.start_date, self.end_date, req.sqm_required)
          raise "Screen #{req.screen_inventory_id} does not have enough sqm during this period"
        end

        req.update!(reserved_at: Time.current)
      end

      
      # Return equipment
      equipment.each { |eq| eq.return_from_order! if eq.status == 'assigned' }
      
      update!(order_status: 'cancelled')
    end
  end
  
  def days_until_start
    return 0 if start_date <= Date.current
    (start_date.to_date - Date.current).to_i
  end
  
  def is_current?
    Date.current.between?(start_date.to_date, end_date.to_date)
  end
  
  def is_upcoming?
    start_date.to_date > Date.current
  end
  
  def is_past?
    end_date.to_date < Date.current
  end
  
  # Method to assign equipment manually when needed
  def assign_equipment_for_event!
    return false unless ['confirmed'].include?(order_status)
    
    # Assign laptops
    laptops_to_assign = Equipment.laptops.available.limit(laptops_needed)
    laptops_to_assign.each { |laptop| laptop.assign_to_order!(self) }
    
    # Assign video processors
    processors_to_assign = Equipment.video_processors.available.limit(video_processors_needed)
    processors_to_assign.each { |processor| processor.assign_to_order!(self) }
    
    {
      laptops_assigned: laptops_to_assign.count,
      processors_assigned: processors_to_assign.count,
      success: (laptops_to_assign.count == laptops_needed && processors_to_assign.count == video_processors_needed)
    }
  end
  
  private
  
  def generate_order_id
    return if order_id.present?

    # 1) date in "DD/MM/YYYY" form
    date_str = Time.zone.today.strftime("%d/%m/%Y")
    # 2) count how many already use this prefix
    today_count = Order.where("order_id LIKE ?", "#{date_str}\\_%").count
    # 3) pick letter: 0→A, 1→B, etc.
    suffix = ( "A".ord + today_count ).chr
    # 4) combine with underscore
    self.order_id = "#{date_str}_#{suffix}"
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
  
  def compatible_screen_types
    pixel_pitches = order_screen_requirements.joins(:screen_inventory)
                                           .distinct
                                           .pluck(:pixel_pitch)
    
    if pixel_pitches.length > 1
      errors.add(:base, 'Cannot mix different pixel pitches in one order')
    end
  end
  
  def sufficient_equipment_available
    # Just log warnings - don't fail validation
    available_laptops = Equipment.laptops.available.count
    available_processors = Equipment.video_processors.available.count
    
    if laptops_needed > available_laptops
      Rails.logger.warn "Order #{order_id || 'new'}: Requesting #{laptops_needed} laptops but only #{available_laptops} available"
    end
    
    if video_processors_needed > available_processors
      Rails.logger.warn "Order #{order_id || 'new'}: Requesting #{video_processors_needed} processors but only #{available_processors} available"
    end
  end
  
  def has_screen_requirements
    # Check in-memory associations (built with .build)
    if order_screen_requirements.size == 0
      errors.add(:base, 'Must have at least one screen requirement')
    end
  end

  def calculate_duration_days
    return unless start_date && end_date
    self.duration_days = (end_date.to_date - start_date.to_date).to_i + 1
  end
  
  # def calculate_due_date
  #   self.due_date = end_date if end_date.present?
  # end

  
  def update_overdue_status
    self.is_overdue = overdue?
  end
  
  def reserve_inventory_and_equipment
    # Auto-reserve screen inventory (this works correctly with dates)
    order_screen_requirements.each do |req|
      req.update!(reserved_at: Time.current)
    end
    
    # Create equipment reservations for the date range
    create_equipment_reservations
  end

  def create_equipment_reservations
    # Get equipment that's actually available for this date range
    available_laptop_ids = Equipment
      .laptops
      .available
      .where.not(id: OrderEquipmentAssignment
        .joins(:order)
        .where(orders: { order_status: 'confirmed' })
        .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
        .where(returned_at: nil)
        .pluck(:equipment_id)
      )
      .limit(laptops_needed)
      .pluck(:id)

    available_processor_ids = Equipment
      .video_processors
      .available
      .where.not(id: OrderEquipmentAssignment
        .joins(:order)
        .where(orders: { order_status: 'confirmed' })
        .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
        .where(returned_at: nil)
        .pluck(:equipment_id)
      )
      .limit(video_processors_needed)
      .pluck(:id)

    
    # Create assignments for available laptops
    available_laptop_ids.each do |laptop_id|
      order_equipment_assignments.create!(
        equipment_id: laptop_id,
        assigned_at: Time.current,
        assignment_status: 'assigned'
      )
      # Update equipment status
      Equipment.find(laptop_id).update!(status: 'assigned')
    end
    
    # Create assignments for available processors
    available_processor_ids.each do |processor_id|
      order_equipment_assignments.create!(
        equipment_id: processor_id,
        assigned_at: Time.current,
        assignment_status: 'assigned'
      )
      # Update equipment status
      Equipment.find(processor_id).update!(status: 'assigned')
    end
    
    Rails.logger.info "Order #{order_id}: Reserved #{available_laptop_ids.count} laptops and #{available_processor_ids.count} processors for dates #{start_date} to #{end_date}"
    
    # Check if we got enough equipment
    if available_laptop_ids.count < laptops_needed || available_processor_ids.count < video_processors_needed
      Rails.logger.warn "Order #{order_id}: Could not reserve enough equipment. Needed: #{laptops_needed} laptops, #{video_processors_needed} processors. Got: #{available_laptop_ids.count} laptops, #{available_processor_ids.count} processors"
    end
  rescue => e
    Rails.logger.error "Failed to create equipment reservations for order #{order_id}: #{e.message}"
    raise e # Re-raise to rollback transaction
  end
  
  def handle_status_changes
    if saved_change_to_order_status?
      case order_status
      when 'cancelled'
        third_party_provider&.update_order_stats!
      end
    end
  end
end