class AddMaintenanceDatesToEquipment < ActiveRecord::Migration[7.1]
  def change
    add_column :equipment, :maintenance_start_date, :date
    add_column :equipment, :maintenance_end_date, :date
  end
end
