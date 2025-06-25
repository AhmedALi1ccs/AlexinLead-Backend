class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      # Company basic info
      t.string :name, null: false, limit: 255
      t.string :contact_person, limit: 255
      t.string :email, limit: 255
      t.string :phone, limit: 20
      t.text :address
      
      # Status and stats
      t.boolean :is_active, default: true
      t.integer :total_orders_count, default: 0    # track performance
      t.decimal :total_revenue_generated, precision: 12, scale: 2, default: 0
      
      t.timestamps
    end
    
    add_index :companies, :name
    add_index :companies, :is_active
  end
end