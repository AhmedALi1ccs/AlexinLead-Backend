class MonthlyTargetSerializer < ActiveModel::Serializer
  attributes :id, :month, :year, :gross_earnings_target, :estimated_fixed_expenses,
             :estimated_variable_expenses, :notes, :created_at, :updated_at,
             :break_even_point, :month_name
  
  belongs_to :created_by, serializer: UserSerializer
  
  def break_even_point
    object.break_even_point
  end
  
  def month_name
    Date::MONTHNAMES[object.month]
  end
end
