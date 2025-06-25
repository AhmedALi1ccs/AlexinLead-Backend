class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      # User who created the order
      t.references :user, null: false, foreign_key: true
      
      # Location (simple approach)
      t.text :google_maps_link    # Store the full Google Maps link
      t.string :location_name, limit: 255    # Optional friendly name
      
      # Physical dimensions
      t.integer :dimensions_rows, null: false
      t.integer :dimensions_columns, null: false
      
      # Timeline
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.integer :duration_days, null: false
      
      # Assignments
      t.references :installing_assignee, null: false, 
                   foreign_key: { to_table: :employees }
      t.references :disassemble_assignee, null: false, 
                   foreign_key: { to_table: :employees }
      t.references :third_party_provider, null: true, 
                   foreign_key: { to_table: :companies }
      
      # Financial
      t.decimal :price_per_sqm, precision: 8, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2    # calculated field
      t.string :payment_status, default: 'not_received', limit: 20
      
      # Order status
      t.string :order_status, default: 'pending', limit: 20
      # pending -> confirmed -> in_progress -> completed
      
      # Optional notes
      t.text :notes
      # REMOVE THESE LINES (Rails creates them automatically):
      t.timestamps
    end
    
    # Indexes for performance and common queries
    add_index :orders, :order_status
    add_index :orders, :payment_status
    add_index :orders, [:start_date, :end_date]
    # Constraints to ensure data quality
    add_check_constraint :orders,
      "payment_status IN ('received', 'not_received')",
      name: 'orders_payment_status_check'
      
    add_check_constraint :orders,
      "order_status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')",
      name: 'orders_status_check'
      
    add_check_constraint :orders,
      "dimensions_rows > 0 AND dimensions_columns > 0 AND price_per_sqm > 0",
      name: 'orders_positive_values_check'
      
    add_check_constraint :orders,
      "end_date > start_date",
      name: 'orders_valid_date_range_check'
  end
end