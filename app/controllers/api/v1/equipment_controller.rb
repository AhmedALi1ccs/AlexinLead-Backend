class Api::V1::EquipmentController < ApplicationController
  before_action :set_equipment, only: [:show, :update, :destroy]
  before_action :authorize_admin!, except: [:index, :show, :availability]
  
  def index
    @equipment = Equipment.all.order(:equipment_type, :model)
    
    # Filters
    @equipment = @equipment.where(equipment_type: params[:equipment_type]) if params[:equipment_type].present?
    @equipment = @equipment.where(status: params[:status]) if params[:status].present?
    @equipment = @equipment.available if params[:available_only] == 'true'
    
    if params[:q].present?
      @equipment = @equipment.where(
        'model ILIKE ? OR serial_number ILIKE ?', 
        "%#{params[:q]}%", "%#{params[:q]}%"
      )
    end
    
    render json: {
      equipment: @equipment.map { |item| serialize_equipment(item) },
      summary: equipment_summary,
      equipment_types: Equipment.distinct.pluck(:equipment_type).sort
    }
  end
  
  def show
    render json: {
      equipment: serialize_equipment(@equipment, include_details: true),
      assignment_history: assignment_history(@equipment)
    }
  end
  
  def create
    @equipment = Equipment.new(equipment_params)
    
    if @equipment.save
      render json: {
        message: 'Equipment created successfully',
        equipment: serialize_equipment(@equipment, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create equipment',
        errors: @equipment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @equipment.update(equipment_params)
      render json: {
        message: 'Equipment updated successfully',
        equipment: serialize_equipment(@equipment, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update equipment',
        errors: @equipment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @equipment.update!(status: 'retired')
    render json: { message: 'Equipment retired successfully' }
  end
  
  def availability
    laptops_available = Equipment.laptops.available.count
    processors_available = Equipment.video_processors.available.count
    cables_available = Equipment.cables.available.count
    
    render json: {
      laptops: {
        available: laptops_available,
        total: Equipment.laptops.where.not(status: 'retired').count,
        items: Equipment.laptops.available.map { |item| serialize_equipment(item) }
      },
      video_processors: {
        available: processors_available,
        total: Equipment.video_processors.where.not(status: 'retired').count,
        items: Equipment.video_processors.available.map { |item| serialize_equipment(item) }
      },
      cables: {
        available: cables_available,
        total: Equipment.cables.where.not(status: 'retired').count,
        items: Equipment.cables.available.map { |item| serialize_equipment(item) }
      },
      can_fulfill_order: laptops_available >= 1 && processors_available >= 1
    }
  end

def availability_for_dates
  start_date = Date.parse(params[:start_date]) rescue Date.current
  end_date = Date.parse(params[:end_date]) rescue Date.current + 7.days
  exclude_order_id = params[:exclude_order_id]

  # Build the base query for assigned equipment
  assigned_equipment_query = OrderEquipmentAssignment
    .joins(:order)
    .where(orders: { order_status: 'confirmed' })
    .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
    .where('order_equipment_assignments.returned_at IS NULL OR order_equipment_assignments.returned_at >= ?', start_date)

  # Exclude equipment from the specified order if exclude_order_id is provided
  if exclude_order_id.present?
    assigned_equipment_query = assigned_equipment_query.where.not(orders: { id: exclude_order_id })
  end

  assigned_equipment_ids = assigned_equipment_query.pluck(:equipment_id)

  availability = {
    laptops: calculate_type_availability('laptop', assigned_equipment_ids),
    video_processors: calculate_type_availability('video_processor', assigned_equipment_ids),
    cables: calculate_type_availability('cable', assigned_equipment_ids)
  }

  render json: {
    availability: availability,
    date_range: { start_date: start_date, end_date: end_date },
    can_fulfill_order: true
  }
end



  
  private
  def calculate_type_availability(type, reserved_ids)
    all_equipment = Equipment.where(equipment_type: type).where.not(status: 'retired')

    {
      available: all_equipment.where.not(id: reserved_ids).count,
      total: all_equipment.count
    }
  end

  
  def set_equipment
    @equipment = Equipment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Equipment not found' }, status: :not_found
  end
  
  def equipment_params
    params.require(:equipment).permit(
      :equipment_type, :model, :serial_number, :status, :purchase_price, :purchase_date, :notes
    )
  end
  
  def serialize_equipment(equipment, include_details: false)
    data = {
      id: equipment.id,
      equipment_type: equipment.equipment_type,
      model: equipment.model,
      serial_number: equipment.serial_number,
      status: equipment.status
    }
    
    if include_details
      data.merge!({
        purchase_price: equipment.purchase_price,
        purchase_date: equipment.purchase_date,
        notes: equipment.notes,
        current_order: equipment.assigned_to_order&.id,
        total_assignments: equipment.order_equipment_assignments.count,
        created_at: equipment.created_at
      })
    end
    
    data
  end
  
  def equipment_summary
    {
      total_items: Equipment.where.not(status: 'retired').count,
      available_items: Equipment.available.count,
      assigned_items: Equipment.assigned.count,
      maintenance_items: Equipment.where(status: 'maintenance').count,
      by_type: {
        laptop: {
          total: Equipment.laptops.where.not(status: 'retired').count,
          available: Equipment.laptops.available.count
        },
        video_processor: {
          total: Equipment.video_processors.where.not(status: 'retired').count,
          available: Equipment.video_processors.available.count
        },
        cable: {
          total: Equipment.cables.where.not(status: 'retired').count,
          available: Equipment.cables.available.count
        }
      }
    }
  end
  
  def assignment_history(equipment)
    equipment.order_equipment_assignments
             .includes(:order)
             .order(assigned_at: :desc)
             .limit(10)
             .map do |assignment|
      {
        order_id: assignment.order.id,
        assigned_at: assignment.assigned_at,
        returned_at: assignment.returned_at,
        assignment_status: assignment.assignment_status,
        duration_days: assignment.duration_days,
        return_notes: assignment.return_notes
      }
    end
  end
end

  