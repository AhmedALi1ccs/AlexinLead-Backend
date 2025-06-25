class AddEquipmentCountsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :laptops_needed, :integer, default: 1, null: false
    add_column :orders, :video_processors_needed, :integer, default: 1, null: false
    
    # Add constraints to ensure positive values
    add_check_constraint :orders,
      "laptops_needed > 0 AND video_processors_needed > 0",
      name: 'orders_positive_equipment_counts_check'
  end
end
