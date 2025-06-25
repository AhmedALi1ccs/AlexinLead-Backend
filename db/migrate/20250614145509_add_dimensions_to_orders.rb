class AddDimensionsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :dimensions_rows, :integer
    add_column :orders, :dimensions_columns, :integer
  end
end
