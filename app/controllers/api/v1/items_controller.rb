class Api::V1::ItemsController < ApplicationController
  before_action :set_item, only: [:show, :update, :destroy, :dispose]
  before_action :check_edit_access, only: [:update, :destroy, :dispose]
  
  def index
    @items = current_user.items
                        .includes(:user)
                        .order(created_at: :desc)
    
    # Filter by status
    @items = @items.where(status: params[:status]) if params[:status].present?
    
    # Filter by category
    @items = @items.where(category: params[:category]) if params[:category].present?
    
    # Filter by location
    @items = @items.where(location: params[:location]) if params[:location].present?
    
    # Search
    if params[:q].present?
      @items = @items.where(
        "name ILIKE :query OR description ILIKE :query OR location ILIKE :query",
        query: "%#{params[:q]}%"
      )
    end
    
    # Simple pagination without kaminari for now
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    offset = (page - 1) * per_page
    
    total_count = @items.count
    @items = @items.limit(per_page).offset(offset)
    
    render json: {
      items: @items.map { |item| serialize_item(item) },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      },
      stats: calculate_stats
    }
  end
  
  def show
    render json: { item: serialize_item(@item, include_details: true) }
  end
  
  def create
    @item = current_user.items.build(item_params)
    
    if @item.save
      render json: { 
        message: 'Item added successfully',
        item: serialize_item(@item, include_details: true)
      }, status: :created
    else
      render json: { 
        error: 'Failed to add item',
        errors: @item.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @item.update(item_params)
      render json: { 
        message: 'Item updated successfully',
        item: serialize_item(@item, include_details: true)
      }
    else
      render json: { 
        error: 'Failed to update item',
        errors: @item.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @item.destroy
    render json: { message: 'Item deleted successfully' }
  end
  
  def dispose
    disposal_reason = params[:disposal_reason]
    
    if disposal_reason.blank?
      render json: { error: 'Disposal reason is required' }, status: :unprocessable_entity
      return
    end
    
    begin
      @item.dispose!(disposal_reason, current_user)
      render json: { 
        message: 'Item disposed successfully',
        item: serialize_item(@item, include_details: true)
      }
    rescue => e
      render json: { 
        error: 'Failed to dispose item',
        message: e.message 
      }, status: :unprocessable_entity
    end
  end
  
  def categories
    categories = current_user.items.active.distinct.pluck(:category).compact.sort
    render json: { categories: categories }
  end
  
  def locations
    locations = current_user.items.active.distinct.pluck(:location).compact.sort
    render json: { locations: locations }
  end
  
  private
  
  def set_item
    @item = current_user.items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Item not found' }, status: :not_found
  end
  
  def check_edit_access
    unless @item.user == current_user || current_user.admin?
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def item_params
    params.require(:item).permit(
      :name, :description, :category, :location, :quantity, :value, :barcode
    )
  end
  
  def serialize_item(item, include_details: false)
    data = {
      id: item.id,
      name: item.name,
      description: item.description,
      category: item.category,
      location: item.location,
      quantity: item.quantity,
      status: item.status,
      created_at: item.created_at,
      updated_at: item.updated_at,
      owner: {
        id: item.user.id,
        name: item.user.full_name
      }
    }
    
    if include_details
      data.merge!({
        value: item.value,
        total_value: item.total_value,
        barcode: item.barcode,
        disposed_at: item.disposed_at,
        disposal_reason: item.disposal_reason
      })
    end
    
    data
  end
  
  def calculate_stats
    items = current_user.items
    {
      total_items: items.active.sum(:quantity),
      total_value: items.active.sum('quantity * COALESCE(value, 0)'),
      categories: items.active.distinct.count(:category),
      disposed_items: items.disposed.sum(:quantity)
    }
  end
end
