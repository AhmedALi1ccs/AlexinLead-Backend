class CreateMonthlyTargets < ActiveRecord::Migration[7.0]
  def change
    create_table :monthly_targets do |t|
      t.integer :month, null: false
      t.integer :year, null: false
      t.decimal :gross_earnings_target, precision: 12, scale: 2, null: false
      t.decimal :estimated_fixed_expenses, precision: 10, scale: 2, default: 0, null: false
      t.decimal :estimated_variable_expenses, precision: 10, scale: 2, default: 0, null: false
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    add_index :monthly_targets, [:year, :month], unique: true
    # Note: created_by_id index is automatically created by t.references
    
    add_check_constraint :monthly_targets,
      "month >= 1 AND month <= 12",
      name: 'valid_month_check'
      
    add_check_constraint :monthly_targets,
      "year >= 2020 AND year <= 2100",
      name: 'valid_year_check'
      
    add_check_constraint :monthly_targets,
      "gross_earnings_target > 0",
      name: 'positive_target_check'
      
    add_check_constraint :monthly_targets,
      "estimated_fixed_expenses >= 0 AND estimated_variable_expenses >= 0",
      name: 'non_negative_expenses_check'
  end
end