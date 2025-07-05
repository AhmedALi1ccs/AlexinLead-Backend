class UpdateAccessLogsForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :access_logs, :users

    add_foreign_key :access_logs, :users, column: :user_id, on_delete: :nullify
  end
end
