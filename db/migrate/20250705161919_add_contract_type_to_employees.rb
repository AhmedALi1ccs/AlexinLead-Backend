class AddContractTypeToEmployees < ActiveRecord::Migration[7.0]
  def change
    add_column :employees, :contract_type, :string
  end
end
