class UpdateOrderAssigneeForeignKeysOnDelete < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :orders, column: :installing_assignee_id
    remove_foreign_key :orders, column: :disassemble_assignee_id

    add_foreign_key :orders, :employees, column: :installing_assignee_id, on_delete: :nullify
    add_foreign_key :orders, :employees, column: :disassemble_assignee_id, on_delete: :nullify
  end
end
