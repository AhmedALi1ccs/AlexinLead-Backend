class CreateDataRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :data_records do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false, limit: 255
      t.text :description
      t.string :data_type, null: false, limit: 50
      t.string :file_path, limit: 500
      t.bigint :file_size
      t.string :checksum, limit: 64  # SHA-256 hash
      t.boolean :is_encrypted, default: false
      t.string :access_level, default: 'private', limit: 20
      t.string :status, default: 'active', limit: 20
      
      t.timestamps
    end
  
    add_index :data_records, :status
    add_index :data_records, :data_type
    add_check_constraint :data_records, "access_level IN ('public', 'shared', 'private')", name: 'data_records_access_level_check'
    add_check_constraint :data_records, "status IN ('active', 'archived', 'deleted')", name: 'data_records_status_check'
  end
end
