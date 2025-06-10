class Api::V1::DataRecordsController < ApplicationController
  before_action :set_data_record, only: [:show, :update, :destroy, :download, :share, :unshare]
  before_action :check_access, only: [:show, :download]
  before_action :check_edit_access, only: [:update, :destroy, :share, :unshare]
  
  def index
    @data_records = current_user.data_records
                                .active
                                .includes(:user)
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(params[:per_page] || 20)
    
    render json: {
      data_records: @data_records.map { |record| serialize_data_record(record) },
      pagination: {
        current_page: params[:page] || 1,
        total_pages: @data_records.total_pages,
        total_count: @data_records.total_count
      }
    }
  end
  
  def show
    AccessLog.log_access(
      user: current_user,
      data_record: @data_record,
      action: 'read',
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    
    render json: { data_record: serialize_data_record(@data_record, include_details: true) }
  end
  
  def create
    @data_record = current_user.data_records.build(data_record_params)
    
    if params[:file]
      handle_file_upload
    end
    
    if @data_record.save
      AccessLog.log_access(
        user: current_user,
        data_record: @data_record,
        action: 'create',
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      render json: { 
        message: 'Data record created successfully',
        data_record: serialize_data_record(@data_record, include_details: true)
      }, status: :created
    else
      render json: { 
        error: 'Failed to create data record',
        errors: @data_record.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def update
    if params[:file]
      handle_file_upload
    end
    
    if @data_record.update(data_record_params)
      AccessLog.log_access(
        user: current_user,
        data_record: @data_record,
        action: 'update',
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      render json: { 
        message: 'Data record updated successfully',
        data_record: serialize_data_record(@data_record, include_details: true)
      }
    else
      render json: { 
        error: 'Failed to update data record',
        errors: @data_record.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @data_record.update!(status: 'deleted')
    
    AccessLog.log_access(
      user: current_user,
      data_record: @data_record,
      action: 'delete',
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    
    render json: { message: 'Data record deleted successfully' }
  end
  
  def download
    if @data_record.file_path && File.exist?(file_full_path)
      AccessLog.log_access(
        user: current_user,
        data_record: @data_record,
        action: 'download',
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      
      send_file file_full_path, 
                filename: File.basename(@data_record.file_path),
                type: determine_content_type,
                disposition: 'attachment'
    else
      render json: { error: 'File not found' }, status: :not_found
    end
  end
  
  def share
    user_to_share_with = User.find_by(email: share_params[:email])
    
    unless user_to_share_with
      render json: { error: 'User not found' }, status: :not_found
      return
    end
    
    permission = @data_record.data_permissions.find_or_initialize_by(user: user_to_share_with)
    permission.assign_attributes(
      permission_type: share_params[:permission_type] || 'read',
      granted_by: current_user,
      expires_at: share_params[:expires_at]
    )
    
    if permission.save
      @data_record.update!(access_level: 'shared') if @data_record.access_level == 'private'
      
      render json: { 
        message: "Data record shared with #{user_to_share_with.email}",
        permission: {
          user_email: user_to_share_with.email,
          permission_type: permission.permission_type,
          expires_at: permission.expires_at
        }
      }
    else
      render json: { 
        error: 'Failed to share data record',
        errors: permission.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def unshare
    user_to_unshare = User.find_by(email: params[:email])
    
    unless user_to_unshare
      render json: { error: 'User not found' }, status: :not_found
      return
    end
    
    permission = @data_record.data_permissions.find_by(user: user_to_unshare)
    
    if permission
      permission.destroy
      render json: { message: "Access removed for #{user_to_unshare.email}" }
    else
      render json: { error: 'Permission not found' }, status: :not_found
    end
  end
  
  def shared
    shared_permissions = current_user.data_permissions
                                    .active
                                    .includes(data_record: :user)
                                    .where(data_records: { status: 'active' })
                                    .order(created_at: :desc)
    
    shared_records = shared_permissions.map(&:data_record).uniq
    
    render json: {
      shared_records: shared_records.map { |record| serialize_data_record(record, include_permission: true) }
    }
  end
  
  def search
    query = params[:q]&.strip
    data_type = params[:data_type]
    
    if query.blank?
      render json: { error: 'Search query is required' }, status: :bad_request
      return
    end
    
    records = current_user.data_records.active
    
    # Search in title and description
    records = records.where(
      "title ILIKE :query OR description ILIKE :query",
      query: "%#{query}%"
    )
    
    # Filter by data type if provided
    records = records.where(data_type: data_type) if data_type.present?
    
    records = records.order(created_at: :desc).limit(50)
    
    render json: {
      search_results: records.map { |record| serialize_data_record(record) },
      query: query,
      data_type: data_type,
      count: records.count
    }
  end
  
  private
  
  def set_data_record
    @data_record = DataRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Data record not found' }, status: :not_found
  end
  
  def check_access
    unless @data_record.accessible_by?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def check_edit_access
    unless @data_record.can_edit?(current_user)
      render json: { error: 'Edit access denied' }, status: :forbidden
    end
  end
  
  def data_record_params
    params.require(:data_record).permit(
      :title, :description, :data_type, :access_level, :is_encrypted
    )
  end
  
  def share_params
    params.require(:share).permit(:email, :permission_type, :expires_at)
  end
  
  def handle_file_upload
    file = params[:file]
    return unless file
    
    # Create uploads directory if it doesn't exist
    uploads_dir = Rails.root.join('storage', 'uploads', current_user.id.to_s)
    FileUtils.mkdir_p(uploads_dir)
    
    # Generate unique filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "#{timestamp}_#{SecureRandom.hex(8)}_#{file.original_filename}"
    file_path = uploads_dir.join(filename)
    
    # Save file
    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end
    
    # Calculate file info
    @data_record.file_path = "uploads/#{current_user.id}/#{filename}"
    @data_record.file_size = File.size(file_path)
    @data_record.checksum = Digest::SHA256.file(file_path).hexdigest
    @data_record.data_type ||= determine_file_type(file.original_filename)
  end
  
  def file_full_path
    Rails.root.join('storage', @data_record.file_path)
  end
  
  def determine_file_type(filename)
    extension = File.extname(filename).downcase
    case extension
    when '.pdf' then 'pdf'
    when '.doc', '.docx' then 'document'
    when '.txt' then 'text'
    when '.jpg', '.jpeg', '.png', '.gif' then 'image'
    when '.zip', '.rar' then 'archive'
    else 'other'
    end
  end
  
  def determine_content_type
    extension = File.extname(@data_record.file_path).downcase
    case extension
    when '.pdf' then 'application/pdf'
    when '.doc' then 'application/msword'
    when '.docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when '.txt' then 'text/plain'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.zip' then 'application/zip'
    else 'application/octet-stream'
    end
  end
  
  def serialize_data_record(record, include_details: false, include_permission: false)
    data = {
      id: record.id,
      title: record.title,
      description: record.description,
      data_type: record.data_type,
      access_level: record.access_level,
      status: record.status,
      file_size: record.file_size,
      has_file: record.file_path.present?,
      created_at: record.created_at,
      updated_at: record.updated_at,
      owner: {
        id: record.user.id,
        name: record.user.full_name,
        email: record.user.email
      }
    }
    
    if include_details
      data.merge!({
        is_encrypted: record.is_encrypted,
        checksum: record.checksum,
        file_path: record.file_path ? File.basename(record.file_path) : nil
      })
    end
    
    if include_permission
      permission = current_user.data_permissions.find_by(data_record: record)
      data[:permission] = {
        type: permission&.permission_type,
        expires_at: permission&.expires_at,
        granted_by: permission&.granted_by&.full_name
      }
    end
    
    data
  end
end