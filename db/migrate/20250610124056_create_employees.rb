class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      # Basic employee info
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.string :email, null: false, limit: 255
      t.string :phone, limit: 20
      
      # Work related
      t.string :role, limit: 50  # installer, technician, etc.
      t.boolean :is_active, default: true
      t.decimal :hourly_rate, precision: 8, scale: 2  # optional wage tracking
      
      t.timestamps
    end
    
    # Indexes for better performance
    add_index :employees, :email, unique: true
    add_index :employees, :is_active
  end
end