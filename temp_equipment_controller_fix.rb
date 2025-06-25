# Update the availability method in app/controllers/api/v1/equipment_controller.rb
# Replace the existing availability method with this:

def availability
  start_date = Date.parse(params[:start_date]) rescue Date.current
  end_date = Date.parse(params[:end_date]) rescue Date.current + 7.days
  
  equipment_availability = calculate_equipment_availability_for_period(start_date, end_date)
  
  render json: {
    **equipment_availability,
    date_range: { start_date: start_date, end_date: end_date },
    can_fulfill_order: equipment_availability[:laptops][:available] >= 1 && 
                      equipment_availability[:video_processors][:available] >= 1
  }
end

private

def calculate_equipment_availability_for_period(start_date, end_date)
  # Get equipment that's assigned during this period
  assigned_equipment_ids = OrderEquipmentAssignment
    .joins(:order)
    .where(orders: { order_status: 'confirmed' })
    .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
    .where(returned_at: nil)
    .pluck(:equipment_id)
  
  {
    laptops: calculate_type_availability('laptop', assigned_equipment_ids),
    video_processors: calculate_type_availability('video_processor', assigned_equipment_ids),
    cables: calculate_type_availability('cable', assigned_equipment_ids)
  }
end

def calculate_type_availability(equipment_type, assigned_equipment_ids)
  total_equipment = Equipment.where(equipment_type: equipment_type)
                             .where.not(status: 'retired')
                             
  available_equipment = total_equipment.where.not(id: assigned_equipment_ids)
                                      .where(status: 'available')
  
  {
    available: available_equipment.count,
    total: total_equipment.count,
    items: available_equipment.map { |item| serialize_equipment(item) }
  }
end
