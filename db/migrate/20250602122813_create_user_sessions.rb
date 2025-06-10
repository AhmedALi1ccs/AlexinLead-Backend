class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :session_token, null: false, limit: 255
      t.inet :ip_address
      t.text :user_agent
      t.datetime :expires_at, null: false
      
      t.timestamps
    end
    
    add_index :user_sessions, :session_token, unique: true
    add_index :user_sessions, [:user_id, :expires_at]
  end
end