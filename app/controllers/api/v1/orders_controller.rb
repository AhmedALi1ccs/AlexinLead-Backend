class Api::V1::OrdersController < ApplicationController
  before_action :set_order, only: [:show, :update, :destroy, :cancel,:pay,:update_payment]
  before_action :check_edit_access, only: [:update, :destroy, :cancel,:pay,:update_payment]
  
  def index
  if current_user.admin? || current_user.role == 'viewer'

  @orders = Order.includes(
    :installing_assignee, :disassemble_assignee, :third_party_provider, :order_screen_requirements, :user
  ).order(created_at: :desc)
  else
  @orders = Order
        .includes(
          :installing_assignee,
          :disassemble_assignee,
          :third_party_provider,
          :order_screen_requirements,
          :user
        )
        .where(
          "installing_assignee_id = :id OR disassemble_assignee_id = :id",
          id: current_user.id
        )
        .order(created_at: :desc)
  end
    # Filters
    @orders = @orders.where(order_status: params[:status]) if params[:status].present?
    @orders = @orders.where(payment_status: params[:payment_status]) if params[:payment_status].present?
    
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @orders = @orders.where(
        start_date: Date.parse(params[:start_date])..Date.parse(params[:end_date])
      )
    end
    
    # Search
    if params[:q].present?
      @orders = @orders.left_joins(:third_party_provider).where(
        "companies.name ILIKE :query OR orders.location_name ILIKE :query OR orders.order_id ILIKE :query",
        query: "%#{params[:q]}%"
      )
    end
    if params[:active].present?
        if params[:active] == 'true'
          @orders = @orders.active
        elsif params[:active] == 'false'
          @orders = @orders.where.not(id: Order.active.select(:id))
        end
    end
    if params[:due_filter].present?
      unpaid_statuses = ['not_received', 'partial']
      @orders = @orders.where(payment_status: unpaid_statuses).where.not(order_status: 'cancelled')

      case params[:due_filter]
      when 'overdue'
        @orders = @orders.where('due_date IS NOT NULL AND due_date < ?', Date.current)
      when 'due_this_week'
        @orders = @orders.where(due_date: Date.current..1.week.from_now)
      end
    end

    
    # Pagination
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    offset = (page - 1) * per_page
    
    total_count = @orders.count
    @orders = @orders.limit(per_page).offset(offset)
    
    render json: {
      orders: @orders.map { |order| serialize_order(order) },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      },
      stats: calculate_order_stats
    }
  end
  def location_suggestions
  query = params[:q].to_s.strip.downcase

  if query.blank?
    return render json: []
  end

  suggestions = Order
    .where("LOWER(location_name) LIKE ?", "%#{query}%")
    .select("DISTINCT location_name, google_maps_link")
    .order("location_name ASC")
    .limit(10)

    render json: suggestions.map { |o| { location_name: o.location_name, google_maps_link: o.google_maps_link } }
  end

  def show
    render json: {
      order: serialize_order(@order, include_details: true),
      screen_requirements: @order.order_screen_requirements.includes(:screen_inventory).map do |req|
        serialize_screen_requirement(req)
      end,
      equipment: @order.equipment.map { |item| serialize_equipment(item) }
    }
  end
  def pay
    amt = params.require(:amount).to_f
    @order.increment!(:payed, amt)
    render json: { order: serialize_order(@order.reload, include_details: true) }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  
  def create
    Rails.logger.debug "👉 params[:order] = #{params[:order].inspect}"
    @order = current_user.orders.build(order_params)
    Rails.logger.debug "👉 @order.total_amount after build = #{@order.total_amount.inspect}"
    @order.order_status = 'confirmed'
    
    # Build screen requirements BEFORE validation/save
    if params[:screen_requirements].present?
      params[:screen_requirements].each do |req|
        @order.order_screen_requirements.build(
          screen_inventory_id: req[:screen_inventory_id],
          sqm_required: req[:sqm_required],
          dimensions_rows: req[:dimensions_rows],
          dimensions_columns: req[:dimensions_columns]
        )
      end
      
      # Populate legacy dimensions fields from first screen requirement
      first_screen = params[:screen_requirements].first
      @order.dimensions_rows = first_screen[:dimensions_rows] || 1
      @order.dimensions_columns = first_screen[:dimensions_columns] || 1
    else
      # Default values if no screen requirements
      @order.dimensions_rows = 1
      @order.dimensions_columns = 1
    end
    Rails.logger.debug "🧪 Order valid? #{@order.valid?}"
    Rails.logger.debug "🧪 Order errors: #{@order.errors.full_messages}"

    @order.order_screen_requirements.each_with_index do |req, i|
      Rails.logger.debug "📦 Screen requirement #{i}: #{req.attributes}"
      Rails.logger.debug "  ↪ Valid? #{req.valid?}"
      Rails.logger.debug "  ↪ Errors: #{req.errors.full_messages}"
    end

    
    if @order.save
    begin
      assign_equipment(@order)
      render json: {
        message: 'Order created and confirmed successfully',
        order: serialize_order(@order, include_details: true)
      }, status: :created
    rescue => e
      @order.destroy # roll back if you can't assign equipment
      render json: {
        error: 'Could not assign equipment',
        details: e.message
      }, status: :unprocessable_entity
    end
    end
  end
  
  def update
    ActiveRecord::Base.transaction do
      if @order.update(order_params)
        if params[:screen_requirements].present?

          params[:screen_requirements].each do |req|
            @order.order_screen_requirements.build(
              screen_inventory_id: req[:screen_inventory_id],
              sqm_required: req[:sqm_required],
              dimensions_rows: req[:dimensions_rows],
              dimensions_columns: req[:dimensions_columns]
            )
          end
          
          # Update legacy dimensions from first screen requirement
          first_screen = params[:screen_requirements].first
          @order.dimensions_rows = first_screen[:dimensions_rows] || 1
          @order.dimensions_columns = first_screen[:dimensions_columns] || 1
          
          # Save to create the screen requirements
          @order.save!
          
          # Reserve the new screen requirements (same as create method)
          @order.order_screen_requirements.each do |req|
            req.update!(reserved_at: Time.current)
          end
          
          Rails.logger.debug "🔧 Screen requirements created and reserved: #{@order.order_screen_requirements.count}"
        end
        
        # STEP 4: Assign equipment (same as create method)
        begin
          assign_equipment(@order)
          Rails.logger.debug "🔧 Equipment assigned successfully"
          
          render json: {
            message: 'Order updated successfully',
            order: serialize_order(@order.reload, include_details: true)
          }
        rescue => e
          Rails.logger.error "❌ Equipment assignment failed: #{e.message}"
          render json: {
            error: 'Could not assign equipment',
            details: e.message
          }, status: :unprocessable_entity
        end
      else
        Rails.logger.error "❌ Order update failed: #{@order.errors.full_messages}"
        render json: {
          error: 'Failed to update order',
          errors: @order.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ Record invalid: #{e.message}"
    render json: {
      error: 'Failed to update order',
      errors: [e.message]
    }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "❌ Unexpected error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: {
      error: 'An unexpected error occurred',
      errors: [e.message]
    }, status: :internal_server_error
  end
  def update_payment
    amount = params.require(:amount).to_f
    payment_status = params.require(:payment_status)

    ActiveRecord::Base.transaction do
      @order.increment!(:payed, amount)
      @order.update!(payment_status: payment_status)
    end

    render json: {
      message: 'Payment updated successfully',
      order: serialize_order(@order.reload, include_details: true)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: 'Failed to update payment',
      errors: [e.message]
    }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Payment update failed: #{e.message}"
    render json: {
      error: 'An unexpected error occurred',
      errors: [e.message]
    }, status: :internal_server_error
  end
  
  def cancel
    if @order.cancel!
      render json: {
        message: 'Order cancelled successfully',
        order: serialize_order(@order, include_details: true)
      }
    else
      render json: {
        error: 'Failed to cancel order',
        errors: @order.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if current_user.admin?
      @order.destroy
      render json: { message: 'Order permanently deleted' }
    else
      render json: { error: 'Only admins can permanently delete orders' }, status: :forbidden
    end
  end
  
  private
  
  def set_order
  if current_user.admin? || current_user.role == 'viewer'
    @order = Order.find(params[:id])
  else
    @order = current_user.orders.find(params[:id])
  end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Order not found' }, status: :not_found
  end

  
  
  def check_edit_access
    unless @order.user == current_user || current_user.admin?
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def order_params
    params.require(:order).permit(
      :google_maps_link, :location_name, :start_date, :end_date,  :due_date,
      :installing_assignee_id, :disassemble_assignee_id,
      :third_party_provider_id, :price_per_sqm, :payment_status, :notes,
      :laptops_needed, :video_processors_needed,
      :total_amount
    )
  end
  
  private

def serialize_order(order, include_details: false, calendar_view: false)
    data = {
      id:                       order.id,
      order_id:                 order.order_id,
      location_name:            order.location_name,
      google_maps_link:         order.google_maps_link,
      start_date:               order.start_date,
      end_date:                 order.end_date,
      due_date:                 order.due_date,
      duration_days:            order.duration_days,
      order_status:             order.order_status,
      payment_status:           order.payment_status,
      total_amount:             order.total_amount,
      laptops_needed:           order.laptops_needed,
      video_processors_needed:  order.video_processors_needed,
      created_at:               order.created_at,
      installing_assignee:      (order.installing_assignee && { id: order.installing_assignee.id, name: order.installing_assignee.full_name }),
      disassemble_assignee:     (order.disassemble_assignee && { id: order.disassemble_assignee.id, name: order.disassemble_assignee.full_name }),
      third_party_provider:     (order.third_party_provider && { id: order.third_party_provider.id, name: order.third_party_provider.name }),
      payed: order.payed,
      remaining: order.remaining,
    }


    data[:payed]     = order.payed
    data[:remaining] = order.remaining

    data[:order_screen_requirements] = order.order_screen_requirements.includes(:screen_inventory).map do |req|
      {
        id: req.id,
        screen_type: req.screen_inventory.screen_type,
        pixel_pitch: req.screen_inventory.pixel_pitch,
        sqm_required: req.sqm_required,
        dimensions_rows: req.dimensions_rows,
        dimensions_columns: req.dimensions_columns,
        calculated_sqm: req.calculated_sqm,
        reserved_at: req.reserved_at,
        configuration: "#{req.dimensions_rows} × #{req.dimensions_columns} panels",
        physical_size: "#{req.dimensions_columns}m × #{req.dimensions_rows}m",
        total_panels: req.dimensions_rows * req.dimensions_columns,
      }
    end

    # Then include other details only if needed
    if include_details
      data.merge!(
        google_maps_link: order.google_maps_link,
        price_per_sqm:    order.price_per_sqm,
        notes:            order.notes,
        can_cancel:       order.can_cancel?,
        assigned_equipment: {
          laptops: order.equipment.laptops.map { |e| serialize_equipment(e) },
          video_processors: order.equipment.video_processors.map { |e| serialize_equipment(e) }
        }
      )
    end


    data
end



  def serialize_screen_requirement(requirement)
    {
      id: requirement.id,
      screen_type: requirement.screen_inventory.screen_type,
      pixel_pitch: requirement.screen_inventory.pixel_pitch,
      sqm_required: requirement.sqm_required,
      dimensions_rows: requirement.dimensions_rows,
      dimensions_columns: requirement.dimensions_columns,
      calculated_sqm: requirement.calculated_sqm,
      reserved_at: requirement.reserved_at,
      configuration: "#{requirement.dimensions_rows} × #{requirement.dimensions_columns} panels",
      physical_size: "#{requirement.dimensions_columns}m × #{requirement.dimensions_rows}m",

      total_panels: requirement.dimensions_rows * requirement.dimensions_columns,
      screen_inventory_id: requirement.screen_inventory_id
    }
  end
  
  def serialize_equipment(equipment)
    {
      id: equipment.id,
      equipment_type: equipment.equipment_type,
      model: equipment.model,
      serial_number: equipment.serial_number,
      status: equipment.status
    }
  end

  def assign_equipment(order)
    assign_equipment_type(order, 'laptop', order.laptops_needed)
    assign_equipment_type(order, 'video_processor', order.video_processors_needed)
  end

def assign_equipment_type(order, type, quantity)
  return if quantity.to_i < 1

  # Identify conflicting equipment
  conflicting_ids = OrderEquipmentAssignment
    .joins(:order)
    .where('orders.start_date <= ? AND orders.end_date >= ?', order.end_date, order.start_date)
    .where(orders: { order_status: ['confirmed', 'in_progress'] })
    .where.not(orders: { id: order.id })
    .where(returned_at: nil)
    .pluck(:equipment_id)

  # Get available equipment
  available_items = Equipment
    .where(equipment_type: type)
    .where.not(status: 'retired')
    .where.not(id: conflicting_ids)
    .distinct
    .limit(quantity)

  raise "Not enough available #{type.pluralize}" if available_items.size < quantity

  available_items.each do |equipment|
    OrderEquipmentAssignment.create!(
      order_id: order.id,
      equipment_id: equipment.id,
      assigned_at: order.start_date
    )
  end
end


  
 def calculate_order_stats
  if current_user.admin?
    orders = Order.all
  else
    orders = current_user.orders
  end
  
  {
    total_orders: orders.count,
    confirmed_orders: orders.where(order_status: 'confirmed').count,
    active_orders: orders.active.count,  # This now means "happening today"
    cancelled_orders: orders.where(order_status: 'cancelled').count,
    total_revenue: orders.where(payment_status: 'received').sum(:total_amount) || 0,
    revenue_this_month: orders.where(
      created_at: Time.current.beginning_of_month..Time.current.end_of_month,
      payment_status: 'received'
    ).sum(:total_amount) || 0,
    partial_payments: orders.where(payment_status: 'partial').count
  }
 end
 
end