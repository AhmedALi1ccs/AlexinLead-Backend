class CreateOrderEquipmentAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :order_equipment_assignments do |t|
      # Links orders to specific equipment items
      t.references :order, null: false, foreign_key: true
      t.references :equipment, null: false, foreign_key: true
      
      # Assignment tracking
      t.datetime :assigned_at, null: false
      t.datetime :returned_at                             # when equipment comes back
      t.string :assignment_status, default: 'assigned', limit: 20
      
      # Optional notes about condition when returned
      t.text :return_notes
      
      t.timestamps
    end
    
    # Prevent same equipment being assigned to multiple active orders
    add_index :order_equipment_assignments, [:order_id, :equipment_id], 
              unique: true, name: 'unique_order_equipment'
              
    add_check_constraint :order_equipment_assignments,
      "assignment_status IN ('assigned', 'returned', 'damaged', 'lost')",
      name: 'assignment_status_check'
  end
end
