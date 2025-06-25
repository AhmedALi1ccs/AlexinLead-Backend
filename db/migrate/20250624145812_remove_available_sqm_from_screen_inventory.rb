class RemoveAvailableSqmFromScreenInventory < ActiveRecord::Migration[7.1]
  def change
    remove_column :screen_inventory,  :available_sqm, :decimal
  end
end
