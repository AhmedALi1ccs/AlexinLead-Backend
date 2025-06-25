class AddMaintenanceDatesToScreens < ActiveRecord::Migration[6.1]
  def change
    # NOTE: your table is singular!
    add_column :screen_inventory, :maintenance_start_date, :date
    add_column :screen_inventory, :maintenance_end_date,   :date
  end
end
