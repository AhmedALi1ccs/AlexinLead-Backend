class AddDimensionsToOrderScreenRequirements < ActiveRecord::Migration[7.1]
  def change
    add_column :order_screen_requirements, :dimensions_rows, :integer
    add_column :order_screen_requirements, :dimensions_columns, :integer
    
    # Add constraints to ensure positive values when present
    add_check_constraint :order_screen_requirements,
      "(dimensions_rows IS NULL OR dimensions_rows > 0) AND (dimensions_columns IS NULL OR dimensions_columns > 0)",
      name: 'order_screen_requirements_positive_dimensions_check'
  end
end
