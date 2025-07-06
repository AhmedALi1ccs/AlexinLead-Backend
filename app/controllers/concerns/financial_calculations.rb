module FinancialCalculations
  extend ActiveSupport::Concern
  
  private
  
  def calculate_monthly_revenue(month, year)
    date_range = Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
    Order.where(created_at: date_range, payment_status: 'received').sum(:total_amount) || 0
  end
  
  def calculate_monthly_expenses(month, year)
    date_range = Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
    Expense.approved.where(expense_date: date_range).sum(:amount) || 0
  end
  
  def calculate_accounts_receivable_summary
    unpaid_orders = Order.where(payment_status: ['not_received', 'partial'])
                        .where.not(order_status: 'cancelled')
    
    total_ar = unpaid_orders.sum('total_amount - payed') || 0
    overdue_ar = unpaid_orders.where('due_date < ?', Date.current).sum('total_amount - payed') || 0
    
    {
      total: total_ar,
      overdue: overdue_ar,
      current: total_ar - overdue_ar,
      count: unpaid_orders.count
    }
  end
  
  def calculate_profit_margins(revenue, expenses)
    return { gross_margin: 0, net_margin: 0 } if revenue == 0
    
    gross_profit = revenue - expenses
    {
      gross_margin: ((gross_profit / revenue) * 100).round(2),
      net_margin: ((gross_profit / revenue) * 100).round(2),
      gross_profit: gross_profit
    }
  end
  
  def format_currency(amount)
    "#{amount.round(2)} SAR"
  end
end
