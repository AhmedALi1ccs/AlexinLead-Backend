class EnhanceExpensesTable < ActiveRecord::Migration[7.0]
  def change
    # Remove old expense type constraint
    remove_check_constraint :expenses, name: 'expense_type_check'
    
    # Add new columns
    add_reference :expenses, :recurring_expense, null: true, foreign_key: true
    add_column :expenses, :contractor_type, :string, limit: 20
    add_column :expenses, :hours_worked, :decimal, precision: 5, scale: 2
    add_column :expenses, :hourly_rate, :decimal, precision: 8, scale: 2
    add_column :expenses, :status, :string, limit: 20, default: 'approved', null: false
    add_reference :expenses, :approved_by, null: true, foreign_key: { to_table: :users }
    add_column :expenses, :approved_at, :datetime
    
    # Add new indexes (only for non-reference columns)
    add_index :expenses, :contractor_type
    add_index :expenses, :status
    # Note: recurring_expense_id and approved_by_id indexes are automatically created by add_reference
    
    # Add new constraints
    add_check_constraint :expenses,
      "expense_type IN ('labor', 'transportation', 'lunch', 'others')",
      name: 'expense_type_check'
      
    add_check_constraint :expenses,
      "contractor_type IN ('salary', 'hourly') OR contractor_type IS NULL",
      name: 'contractor_type_check'
      
    add_check_constraint :expenses,
      "status IN ('pending', 'approved', 'rejected')",
      name: 'expense_status_check'
      
    add_check_constraint :expenses,
      "(contractor_type = 'hourly' AND hours_worked IS NOT NULL AND hourly_rate IS NOT NULL) OR contractor_type != 'hourly' OR contractor_type IS NULL",
      name: 'hourly_contractor_fields_check'
      
    add_check_constraint :expenses,
      "hours_worked IS NULL OR hours_worked > 0",
      name: 'positive_hours_check'
      
    add_check_constraint :expenses,
      "hourly_rate IS NULL OR hourly_rate > 0",
      name: 'positive_hourly_rate_check'
  end
end