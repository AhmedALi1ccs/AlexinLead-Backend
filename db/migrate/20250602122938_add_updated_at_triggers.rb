class AddUpdatedAtTriggers < ActiveRecord::Migration[7.1]
  def up
    # Create the trigger function
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL
    
    # Add triggers to tables
    execute <<-SQL
      CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    SQL
    
    execute <<-SQL
      CREATE TRIGGER update_data_records_updated_at BEFORE UPDATE ON data_records
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    SQL
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS update_users_updated_at ON users;"
    execute "DROP TRIGGER IF EXISTS update_data_records_updated_at ON data_records;"
    execute "DROP FUNCTION IF EXISTS update_updated_at_column();"
  end
end