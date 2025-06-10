class CreateDataPermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :data_permissions do |t|
      t.references :data_record, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :permission_type, default: 'read', limit: 20
      t.references :granted_by, null: true, foreign_key: { to_table: :users }
      t.datetime :expires_at
      
      t.timestamps
    end
    
    add_index :data_permissions, [:data_record_id, :user_id], unique: true
    add_check_constraint :data_permissions, "permission_type IN ('read', 'write', 'admin')", name: 'data_permissions_permission_type_check'
  end
end