class AddAccountsReceivableFields < ActiveRecord::Migration[7.0]
  def change
    # Add fields to orders table for better AR tracking
    add_column :orders, :due_date, :date
    add_column :orders, :invoice_number, :string, limit: 100
    add_column :orders, :payment_terms, :string, limit: 50, default: 'net_30'
    add_column :orders, :invoice_sent_at, :datetime
    add_column :orders, :last_reminder_sent_at, :datetime
    add_column :orders, :is_overdue, :boolean, default: false, null: false
    
    # Add indexes for AR queries
    add_index :orders, :due_date
    add_index :orders, :invoice_number, unique: true
    add_index :orders, :payment_terms
    add_index :orders, :is_overdue
    add_index :orders, [:payment_status, :due_date]
    
    # Add constraints
    add_check_constraint :orders,
      "payment_terms IN ('net_15', 'net_30', 'net_45', 'net_60', 'due_on_receipt', 'advance_payment')",
      name: 'valid_payment_terms_check'
      
    add_check_constraint :orders,
      "due_date IS NULL OR due_date >= start_date",
      name: 'valid_due_date_check'
  end
end