class CreateScreenMaintenances < ActiveRecord::Migration[7.1]
  def change
  create_table :screen_maintenances do |t|
  t.references :screen_inventory,
               foreign_key: { to_table: :screen_inventory },
               index: true
  t.decimal   :sqm, precision: 8, scale: 2, null: false
  t.date      :maintenance_start_date, null: false
  t.date      :maintenance_end_date,   null: false

  t.timestamps
end

  end
end
