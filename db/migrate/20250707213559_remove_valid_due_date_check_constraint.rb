class RemoveValidDueDateCheckConstraint < ActiveRecord::Migration[7.0]
  def change
    remove_check_constraint :orders, name: "valid_due_date_check"
  end
end
