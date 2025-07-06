class CreateFinancialSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :financial_settings do |t|
      t.decimal :partner_1_percentage, precision: 5, scale: 2, default: 33.33, null: false
      t.decimal :partner_2_percentage, precision: 5, scale: 2, default: 33.33, null: false
      t.decimal :company_saving_percentage, precision: 5, scale: 2, default: 33.34, null: false
      t.string :partner_1_name, limit: 100, default: 'Partner 1', null: false
      t.string :partner_2_name, limit: 100, default: 'Partner 2', null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
    
    add_index :financial_settings, :is_active
    
    add_check_constraint :financial_settings,
      "partner_1_percentage + partner_2_percentage + company_saving_percentage = 100",
      name: 'profit_sharing_percentage_check'
      
    add_check_constraint :financial_settings,
      "partner_1_percentage > 0 AND partner_2_percentage > 0 AND company_saving_percentage > 0",
      name: 'positive_percentages_check'
  end
end