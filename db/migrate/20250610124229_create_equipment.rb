class CreateEquipment < ActiveRecord::Migration[7.1]
  def change
    create_table :equipment do |t|
      # Equipment details
      t.string :equipment_type, null: false, limit: 50
      t.string :model, limit: 100
      t.string :serial_number, limit: 100
      t.string :status, default: 'available', limit: 20
      
      # Optional purchase info
      t.decimal :purchase_price, precision: 8, scale: 2
      t.date :purchase_date
      t.text :notes
      
      t.timestamps
    end  # ← This ends the create_table block
    
    add_index :equipment, :equipment_type
    add_index :equipment, :status
    add_index :equipment, :serial_number, unique: true
    
    add_check_constraint :equipment,
      "equipment_type IN ('laptop', 'video_processor', 'cable')",
      name: 'equipment_type_check'
      
    add_check_constraint :equipment,
      "status IN ('available', 'assigned', 'maintenance', 'damaged', 'retired')",
      name: 'equipment_status_check'
  end  # ← This ends the def change method
end    # ← This ends the class