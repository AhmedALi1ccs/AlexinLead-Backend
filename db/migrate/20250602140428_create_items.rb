class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 255
      t.text :description
      t.string :category, limit: 100
      t.string :location, limit: 255
      t.integer :quantity, default: 1
      t.string :status, default: 'active', limit: 50
      t.datetime :disposed_at
      t.text :disposal_reason
      t.decimal :value, precision: 10, scale: 2
      t.string :barcode, limit: 100
      
      t.timestamps
    end
    
    # Only add indexes if they don't exist
    add_index :items, :status unless index_exists?(:items, :status)
    add_index :items, :category unless index_exists?(:items, :category)
    add_index :items, :location unless index_exists?(:items, :location)
    
    add_check_constraint :items, "status IN ('active', 'disposed', 'maintenance', 'reserved')", name: 'items_status_check'
  end
end
