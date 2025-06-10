class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 255
      t.string :password_digest, null: false, limit: 255
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.string :role, default: 'user', limit: 50
      t.boolean :is_active, default: true
      t.datetime :last_login_at
      t.integer :failed_login_attempts, default: 0
      t.datetime :locked_until
      
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :is_active
    add_check_constraint :users, "role IN ('admin', 'user', 'viewer')", name: 'users_role_check'
  end
end
