class AddActiveToOrderScreenRequirements < ActiveRecord::Migration[7.0]
  def change
    add_column :order_screen_requirements, :active, :boolean, default: true, null: false
  end
end
