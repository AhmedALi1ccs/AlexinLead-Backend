class AddPayedToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :payed, :decimal,
               precision: 10, scale: 2,
               null: false, default: 0.0
  end
end
