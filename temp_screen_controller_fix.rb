# Update the availability method in app/controllers/api/v1/screen_inventory_controller.rb
# Replace the existing availability method with this:

def availability
  start_date = Date.parse(params[:start_date]) rescue Date.current
  end_date = Date.parse(params[:end_date]) rescue Date.current + 7.days
  required_sqm = params[:required_sqm].to_f
  pixel_pitch = params[:pixel_pitch]
  
  available_screens = ScreenInventory.active
  available_screens = available_screens.by_pixel_pitch(pixel_pitch) if pixel_pitch.present?
  
  availability_data = available_screens.map do |screen|
    available_sqm_for_period = calculate_available_sqm_for_period(screen, start_date, end_date)
    is_available = required_sqm > 0 ? available_sqm_for_period >= required_sqm : available_sqm_for_period > 0
    
    {
      id: screen.id,
      screen_type: screen.screen_type,
      pixel_pitch: screen.pixel_pitch,
      total_sqm_owned: screen.total_sqm_owned,
      available_sqm: screen.available_sqm, # Current availability
      available_sqm_for_period: available_sqm_for_period, # Availability for the specific period
      is_available: is_available,
      max_available_for_period: available_sqm_for_period,
      description: screen.description
    }
  end
  
  render json: {
    availability: availability_data,
    date_range: { start_date: start_date, end_date: end_date },
    required_sqm: required_sqm
  }
end

private

def calculate_available_sqm_for_period(screen, start_date, end_date)
  # Calculate how much is reserved during this specific period
  reserved_sqm = screen.order_screen_requirements
                      .joins(:order)
                      .where(orders: { order_status: 'confirmed' }) # Only confirmed orders
                      .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
                      .sum(:sqm_required)
  
  screen.total_sqm_owned - reserved_sqm
end
