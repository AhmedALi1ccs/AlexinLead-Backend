class CreateOrderScreenRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :order_screen_requirements do |t|
      # Links order to specific screen types
      t.references :order, null: false, foreign_key: true
      t.references :screen_inventory, null: false, foreign_key: { to_table: :screen_inventory }
      # How much of this screen type is needed
      t.decimal :sqm_required, precision: 8, scale: 2, null: false
      
      # Reservation tracking (when confirmed)
      t.datetime :reserved_at    # when inventory was blocked
      t.datetime :released_at    # when returned to inventory
      
      t.timestamps
    end
    
    # Ensure we don't double-book same screen type for same order
    add_index :order_screen_requirements, [:order_id, :screen_inventory_id], 
              unique: true, name: 'unique_order_screen'
              
    add_check_constraint :order_screen_requirements,
      "sqm_required > 0",
      name: 'positive_sqm_required_check'
  end
end
