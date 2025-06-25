class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      # Link to order (optional - some expenses might be general)
      t.references :order, null: true, foreign_key: true
      
      # Expense details
      t.string :expense_type, null: false, limit: 50     # wages, transportation, additions
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :expense_date, null: false
      t.text :description
      
      # Who recorded this expense
      t.references :user, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :expenses, :expense_type
    add_index :expenses, :expense_date
    
    add_check_constraint :expenses,
      "expense_type IN ('wages', 'transportation', 'additions')",
      name: 'expense_type_check'
      
    add_check_constraint :expenses,
      "amount > 0",
      name: 'positive_amount_check'
  end
end
