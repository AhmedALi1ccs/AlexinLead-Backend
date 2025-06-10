class CreateAccessLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :access_logs do |t|
      t.references :user, null: true, foreign_key: { on_delete: :nullify }
      t.references :data_record, null: true, foreign_key: { on_delete: :cascade }
      t.string :action, null: false, limit: 50
      t.inet :ip_address
      t.text :user_agent
      t.boolean :success, default: true
      t.text :error_message
      
      t.timestamps
    end
    
    #add_index :access_logs, :data_record_id
    add_index :access_logs, :created_at
    add_index :access_logs, :action
  end
end