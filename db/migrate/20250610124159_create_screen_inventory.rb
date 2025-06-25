class CreateScreenInventory < ActiveRecord::Migration[7.1]
  def change
    create_table :screen_inventory do |t|
      # Screen specifications
      t.string :screen_type, null: false, limit: 20    # P2.6B1, P2.6B2, etc.
      t.string :pixel_pitch, null: false, limit: 10    # 2.6, 3.9, 4.0, etc.
      t.decimal :total_sqm_owned, precision: 8, scale: 2, null: false    # Total M² we own
      t.decimal :available_sqm, precision: 8, scale: 2, null: false  
      
      # Optional details
      t.text :description
      t.boolean :is_active, default: true
      
      t.timestamps
    end
    
    # Each screen type should be unique
    add_index :screen_inventory, :screen_type, unique: true
    add_index :screen_inventory, :pixel_pitch
    add_index :screen_inventory, :is_active
    # Ensure available_sqm never exceeds total_sqm_owned
    add_check_constraint :screen_inventory,
    "available_sqm <= total_sqm_owned AND available_sqm >= 0",
    name: 'valid_available_sqm_check'
  end
  
end