class CreateRecurringExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :recurring_expenses do |t|
      t.string :name, limit: 255, null: false
      t.string :expense_type, limit: 50, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :frequency, limit: 20, null: false # monthly, weekly, daily
      t.date :start_date, null: false
      t.date :end_date
      t.boolean :is_active, default: true, null: false
      t.text :description
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    add_index :recurring_expenses, :expense_type
    add_index :recurring_expenses, :frequency
    add_index :recurring_expenses, :is_active
    add_index :recurring_expenses, :start_date
    
    add_check_constraint :recurring_expenses,
      "expense_type IN ('labor', 'transportation', 'lunch', 'others')",
      name: 'recurring_expense_type_check'
      
    add_check_constraint :recurring_expenses,
      "frequency IN ('monthly', 'weekly', 'daily')",
      name: 'valid_frequency_check'
      
    add_check_constraint :recurring_expenses,
      "amount > 0",
      name: 'positive_recurring_amount_check'
      
    add_check_constraint :recurring_expenses,
      "end_date IS NULL OR end_date >= start_date",
      name: 'valid_date_range_check'
  end
end