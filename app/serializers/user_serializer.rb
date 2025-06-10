class UserSerializer
  include JSONAPI::Serializer
  
  attributes :id, :email, :first_name, :last_name, :role, :is_active, :last_login_at, :created_at
  
  attribute :full_name do |user|
    user.full_name
  end
  
  attribute :admin do |user|
    user.admin?
  end
end