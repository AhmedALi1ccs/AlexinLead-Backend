class FinancialSettingSerializer < ActiveModel::Serializer
  attributes :id, :partner_1_name, :partner_1_percentage, :partner_2_name, 
             :partner_2_percentage, :company_saving_percentage, :is_active, 
             :created_at, :updated_at
end
