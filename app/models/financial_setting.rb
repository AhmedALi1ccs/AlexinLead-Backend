class FinancialSetting < ApplicationRecord
  validates :partner_1_percentage, :partner_2_percentage, :company_saving_percentage,
            presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :partner_1_name, :partner_2_name, presence: true
  validate :percentages_sum_to_100
  
  scope :active, -> { where(is_active: true) }
  
  def self.current
    active.last || create_default
  end
  
  def self.create_default
    create!(
      partner_1_percentage: 33.33,
      partner_2_percentage: 33.33,
      company_saving_percentage: 33.34,
      partner_1_name: 'Partner 1',
      partner_2_name: 'Partner 2'
    )
  end
  
  def calculate_shares(net_income)
    return { partner_1: 0, partner_2: 0, company_saving: 0 } if net_income <= 0
    
    {
      partner_1: (net_income * partner_1_percentage / 100).round(2),
      partner_2: (net_income * partner_2_percentage / 100).round(2),
      company_saving: (net_income * company_saving_percentage / 100).round(2)
    }
  end
  
  private
  
  def percentages_sum_to_100
    total = partner_1_percentage + partner_2_percentage + company_saving_percentage
    errors.add(:base, 'Percentages must sum to 100') unless total == 100
  end
end
