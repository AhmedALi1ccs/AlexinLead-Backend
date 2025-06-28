class Api::V1::CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :update, :destroy]
  before_action :authorize_admin!, except: [:index, :show]
  
  def index
  @companies = Company.all.order(:name)
  
  # Search by name or contact person
  if params[:q].present?
    @companies = @companies.where(
      'name ILIKE ? OR contact_person ILIKE ?', 
      "%#{params[:q]}%", 
      "%#{params[:q]}%"
    )
  end
  
  # Filter by active status
  case params[:active_only]
  when 'true'
    @companies = @companies.where(is_active: true)
  when 'false'
    @companies = @companies.where(is_active: false)
  # when nil or empty string - return all companies (no filter)
  end
  
  # Pagination
  page = params[:page]&.to_i || 1
  per_page = params[:per_page]&.to_i || 20
  
  total_count = @companies.count
  total_pages = (total_count.to_f / per_page).ceil
  
  @companies = @companies.offset((page - 1) * per_page).limit(per_page)
  
  render json: {
    companies: @companies.map { |company| serialize_company(company) },
    pagination: {
      current_page: page,
      total_pages: total_pages,
      total_count: total_count,
      per_page: per_page
    },
    top_performers: Company.top_performers.active.limit(5).map { |company| serialize_company(company, include_stats: true) }
  }
end
  
  def show
    render json: {
      company: serialize_company(@company, include_details: true),
      recent_orders: @company.orders.includes(:user).order(created_at: :desc).limit(10).map { |order| serialize_order_summary(order) }
    }
  end
  
  def create
    @company = Company.new(company_params)
    
    if @company.save
      render json: {
        message: 'Company created successfully',
        company: serialize_company(@company, include_details: true)
      }, status: :created
    else
      render json: {
        error: 'Failed to create company',
        errors: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if @company.update(company_params)
      render json: {
        message: 'Company updated successfully',
        company: serialize_company(@company, include_details: true)
      }
    else
      render json: {
        error: 'Failed to update company',
        errors: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
def deactivate
  @company.update!(is_active: false)
  render json: { message: 'Company deactivated successfully' }
end
 def destroy
  @company.destroy!
  render json: { message: 'Company deleted permanently' }
end
  
  def stats
    render json: {
      total_companies: Company.active.count,
      companies_with_orders: Company.joins(:orders).distinct.count,
      top_revenue_generator: Company.top_performers.first&.name,
      total_revenue_generated: Company.sum(:total_revenue_generated)
    }
  end
  
  private
  
  def set_company
    @company = Company.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Company not found' }, status: :not_found
  end
  
  def company_params
    params.require(:company).permit(
      :name, :contact_person, :email, :phone, :address, :is_active
    )
  end
  
  def serialize_company(company, include_details: false, include_stats: false)
    data = {
      id: company.id,
      name: company.name,
      contact_person: company.contact_person,
      is_active: company.is_active
    }
    
    if include_details
      data.merge!({
        email: company.email,
        phone: company.phone,
        address: company.address,
        created_at: company.created_at
      })
    end
    
    if include_stats || include_details
      data.merge!({
        total_orders_count: company.total_orders_count,
        total_revenue_generated: company.total_revenue_generated,
        revenue_this_month: company.revenue_this_month
      })
    end
    
    data
  end
  
  def serialize_order_summary(order)
    {
      id: order.id,
      location_name: order.location_name,
      total_amount: order.total_amount,
      order_status: order.order_status,
      payment_status: order.payment_status,
      start_date: order.start_date,
      created_at: order.created_at
    }
  end
end
