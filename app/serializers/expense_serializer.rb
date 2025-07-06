class ExpenseSerializer < ActiveModel::Serializer
  attributes :id, :expense_type, :amount, :expense_date, :description, :status,
             :contractor_type, :hours_worked, :hourly_rate, :created_at, :updated_at,
             :auto_generated, :approved_at
  
  belongs_to :user, serializer: UserSerializer
  belongs_to :order, if: :has_order
  belongs_to :recurring_expense, serializer: RecurringExpenseSerializer, if: :has_recurring_expense?
  belongs_to :approved_by, serializer: UserSerializer, if: :has_approved_by?
  
  def auto_generated
    object.auto_generated?
  end
  
  def has_order?
    object.order.present?
  end
  
  def has_recurring_expense?
    object.recurring_expense.present?
  end
  
  def has_approved_by?
    object.approved_by.present?
  end
end
