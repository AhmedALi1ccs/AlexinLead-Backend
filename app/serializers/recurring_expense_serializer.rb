class RecurringExpenseSerializer < ActiveModel::Serializer
  attributes :id, :name, :expense_type, :amount, :frequency, :start_date, 
             :end_date, :is_active, :description, :created_at, :updated_at,
             :next_expense_date, :expenses_count
  
  belongs_to :created_by, serializer: UserSerializer
  
  def next_expense_date
    object.next_expense_date
  end
  
  def expenses_count
    object.expenses.count
  end
end
