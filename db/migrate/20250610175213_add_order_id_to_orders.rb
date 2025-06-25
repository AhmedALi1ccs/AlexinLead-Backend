class AddOrderIdToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :order_id, :string, limit: 50
    add_index :orders, :order_id, unique: true

    # Update existing check constraints
    remove_check_constraint :orders, name: 'orders_payment_status_check'
    remove_check_constraint :orders, name: 'orders_status_check'

    add_check_constraint :orders,
      "payment_status IN ('received', 'not_received', 'partial')",
      name: 'orders_payment_status_check'

    add_check_constraint :orders,
      "order_status IN ('confirmed', 'cancelled')",
      name: 'orders_status_check'
  end
end