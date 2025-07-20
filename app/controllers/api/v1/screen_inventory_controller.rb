class Api::V1::ScreenInventoryController < ApplicationController
  before_action :set_screen_inventory, only: [:show, :update, :destroy]
  before_action :authorize_admin!, except: [:index, :show, :availability, :availability_by_dates]
  
  def index
    start_date = Date.parse(params[:start_date]) rescue Date.current
    end_date   = Date.parse(params[:end_date])   rescue Date.current + 7.days

    screens = ScreenInventory.active.order(:screen_type)

    availability = screens.map do |screen|
      reserved = screen.order_screen_requirements
                    .joins(:order)
                    .where(orders: { order_status: %w[confirmed in_progress] })
                    .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
                    .sum(:sqm_required)
    maint    = screen.maintenance_sqm_between(start_date, end_date)
    avail    = [screen.total_sqm_owned - reserved - maint, 0].max

      {
        id:               screen.id,
        screen_type:      screen.screen_type,
        pixel_pitch:      screen.pixel_pitch,
        total_sqm_owned:  screen.total_sqm_owned,
        reserved_sqm:     reserved,
        maintenance_sqm:  maint,
        available_sqm:    avail,
        is_available:     (avail > 0)
      }
    end

    render json: {
      availability: availability,
      date_range:   { start_date: start_date, end_date: end_date }
    }
  end


  
  def show
    render json: {
      screen_inventory: serialize_screen_inventory(@screen_inventory, include_details: true),
      current_reservations: current_reservations_for_screen(@screen_inventory)
    }
  end
  
  def create
    @screen_inventory = ScreenInventory.new(screen_inventory_params)
    
    if @screen_inventory.save
      render json: {
        message: 'Screen inventory created successfully',
        screen_inventory: serialize_screen_inventory(@screen_inventory, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create screen inventory',
        errors: @screen_inventory.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @screen_inventory.update(screen_inventory_params)
      render json: {
        message: 'Screen inventory updated successfully',
        screen_inventory: serialize_screen_inventory(@screen_inventory, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update screen inventory',
        errors: @screen_inventory.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @screen_inventory.update!(is_active: false)
    render json: { message: 'Screen inventory deactivated successfully' }
  end
  
  
  def availability
    start_date   = Date.parse(params[:start_date]) rescue Date.current
    end_date     = Date.parse(params[:end_date])   rescue Date.current + 7.days
    required_sqm = params[:required_sqm].to_f
    pixel_pitch  = params[:pixel_pitch]
    exclude_order_id = params[:exclude_order_id]

    screens = ScreenInventory.active
    screens = screens.by_pixel_pitch(pixel_pitch) if pixel_pitch.present?

    availability_data = screens.map do |screen|
      # 1) Build the base query for reserved by orders
      reserved_query = screen.order_screen_requirements
                            .joins(:order)
                            .where(orders: { order_status: %w[confirmed in_progress] })
                            .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)

      # Exclude screen requirements from the specified order if exclude_order_id is provided
      if exclude_order_id.present?
        reserved_query = reserved_query.where.not(orders: { id: exclude_order_id })
      end

      reserved_sqm = reserved_query.sum(:sqm_required)

      # 2) under maintenance
      maint_sqm = screen.maintenance_sqm_between(start_date, end_date)

      # 3) net available
      avail_sqm = screen.total_sqm_owned - reserved_sqm - maint_sqm

      {
        id:                      screen.id,  
        screen_type:             screen.screen_type,
        pixel_pitch:             screen.pixel_pitch,
        total_sqm_owned:         screen.total_sqm_owned,
        reserved_sqm:            reserved_sqm,
        maintenance_sqm:         maint_sqm,
        is_available:            (avail_sqm >= required_sqm),
        max_available_for_period: [avail_sqm, 0].max
      }
    end

    render json: {
      availability: availability_data,
      date_range:   { start_date: start_date, end_date: end_date },
      required_sqm: required_sqm
    }
  end

  def availability_by_dates
    start_date = Date.parse(params[:start_date]) rescue Date.current
    end_date   = Date.parse(params[:end_date])   rescue Date.current + 7.days

    availability_data = ScreenInventory.active.map do |screen|
      reserved_sqm = screen.order_screen_requirements
                         .joins(:order)
                         .where(orders: { order_status: %w[confirmed in_progress] })
                         .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
                         .sum(:sqm_required)

      maint_sqm = screen.maintenance_sqm_between(start_date, end_date)

      {
        id:                     screen.id,
        screen_type:            screen.screen_type,
        pixel_pitch:            screen.pixel_pitch,
        total_sqm_owned:        screen.total_sqm_owned,
        reserved_sqm:           reserved_sqm,
        maintenance_sqm:        maint_sqm,
        utilization_percentage: ((reserved_sqm / screen.total_sqm_owned.to_f) * 100).round(1)
      }
    end

    render json: {
      availability:        availability_data,
      date_range:          { start_date: start_date, end_date: end_date },
      total_available_sqm: availability_data.sum { |i| i[:available_sqm] }
    }
  end
  
  private
  
  def set_screen_inventory
    @screen_inventory = ScreenInventory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Screen inventory not found' }, status: :not_found
  end
  
  def screen_inventory_params
    params.require(:screen_inventory).permit(
      :screen_type,
      :pixel_pitch,
      :total_sqm_owned,
      :description,
      :is_active
    )
  end

  
  def serialize_screen_inventory(screen, include_details: false)
    data = {
      id:               screen.id,
      screen_type:      screen.screen_type,
      pixel_pitch:      screen.pixel_pitch,
      total_sqm_owned:  screen.total_sqm_owned,
      is_active:        screen.is_active
    }

    if include_details
      data.merge!(
        description:   screen.description,
        total_orders:  screen.orders.count,
        active_orders: screen.orders.active.count,
        created_at:    screen.created_at
      )
    end

    data
  end


  def current_reservations_for_screen(screen)
    screen.order_screen_requirements
          .joins(:order)
          .where(orders: { order_status: ['confirmed', 'in_progress'] })
          .includes(:order)
          .map do |req|
      {
        order_id: req.order.id,
        sqm_required: req.sqm_required,
        start_date: req.order.start_date,
        end_date: req.order.end_date,
        reserved_at: req.reserved_at
      }
    end
  end
  
  def calculate_max_available_for_period(screen, start_date, end_date)
    reserved_sqm = screen.order_screen_requirements
                        .joins(:order)
                        .where(orders: { order_status: ['confirmed', 'in_progress'] })
                        .where('orders.start_date <= ? AND orders.end_date >= ?', end_date, start_date)
                        .sum(:sqm_required)
    
    screen.total_sqm_owned - reserved_sqm
  end
end