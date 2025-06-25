class RemoveLegacyDimensionsFromOrders < ActiveRecord::Migration[7.1]
  def change
    remove_column :orders, :dimensions_rows, :integer
    remove_column :orders, :dimensions_columns, :integer
  end
end
