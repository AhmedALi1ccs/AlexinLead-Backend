class Api::V1::FinanceController < ApplicationController
  def overview
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    date_range = Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
    
    # Revenue calculation
    revenue_orders = Order.joins(:order_screen_requirements)
                         .where(created_at: date_range, payment_status: 'received')
    
    total_revenue = revenue_orders.sum(:total_amount) || 0
    
    # Expenses calculation
    total_expenses = Expense.where(expense_date: date_range).sum(:amount) || 0
    
    # Gross profit
    gross_profit = total_revenue - total_expenses
    
    render json: {
      period: { month: month, year: year },
      revenue: {
        total: total_revenue,
        orders_count: revenue_orders.count,
        average_order_value: revenue_orders.count > 0 ? (total_revenue / revenue_orders.count).round(2) : 0,
        top_clients: top_clients_for_period(date_range)
      },
      expenses: {
        total: total_expenses,
        by_type: {
          wages: Expense.by_type_for_month('wages', month, year),
          transportation: Expense.by_type_for_month('transportation', month, year),
          additions: Expense.by_type_for_month('additions', month, year)
        }
      },
      profit: {
        gross_profit: gross_profit,
        profit_margin: total_revenue > 0 ? ((gross_profit / total_revenue) * 100).round(2) : 0
      },
      outstanding_payments: outstanding_payments_summary
    }
  end
  
  def monthly_comparison
    months = 6 # Last 6 months
    current_date = Date.current
    
    monthly_data = (0...months).map do |i|
      date = current_date - i.months
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      
      revenue = Order.where(
        created_at: month_start..month_end,
        payment_status: 'received'
      ).sum(:total_amount) || 0
      
      expenses = Expense.where(
        expense_date: month_start..month_end
      ).sum(:amount) || 0
      
      {
        month: date.strftime('%B %Y'),
        revenue: revenue,
        expenses: expenses,
        profit: revenue - expenses,
        orders_count: Order.where(created_at: month_start..month_end).count
      }
    end.reverse
    
    render json: {
      monthly_data: monthly_data,
      trends: calculate_trends(monthly_data)
    }
  end
  
  def revenue_breakdown
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    date_range = Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
    
    # By screen type
    screen_revenue = Order.joins(:order_screen_requirements => :screen_inventory)
                         .where(created_at: date_range, payment_status: 'received')
                         .group('screen_inventory.screen_type')
                         .sum(:total_amount)
    
    # By client
    client_revenue = Order.joins(:third_party_provider)
                         .where(created_at: date_range, payment_status: 'received')
                         .group('companies.name')
                         .sum(:total_amount)
                         .sort_by { |_, revenue| -revenue }
                         .first(10)
    
    # By order duration
    duration_revenue = Order.where(created_at: date_range, payment_status: 'received')
                           .group(:duration_days)
                           .sum(:total_amount)
    
    render json: {
      by_screen_type: screen_revenue,
      by_client: Hash[client_revenue],
      by_duration: duration_revenue,
      period: { month: month, year: year }
    }
  end
  
  private
  
  def top_clients_for_period(date_range)
    Order.joins(:third_party_provider)
         .where(created_at: date_range, payment_status: 'received')
         .group('companies.name', 'companies.id')
         .sum(:total_amount)
         .map { |(name, id), revenue| { name: name, id: id, revenue: revenue } }
         .sort_by { |client| -client[:revenue] }
         .first(5)
  end
  
  def outstanding_payments_summary
    unpaid_orders = Order.where(payment_status: 'not_received')
                        .where.not(order_status: 'cancelled')
    
    {
      total_amount: unpaid_orders.sum(:total_amount) || 0,
      orders_count: unpaid_orders.count,
      overdue_orders: unpaid_orders.where('end_date < ?', Date.current).count,
      oldest_unpaid: unpaid_orders.order(:created_at).first&.created_at
    }
  end
  
  def calculate_trends(monthly_data)
    return {} if monthly_data.length < 2
    
    current_month = monthly_data.last
    previous_month = monthly_data[-2]
    
    {
      revenue_change: calculate_percentage_change(previous_month[:revenue], current_month[:revenue]),
      expense_change: calculate_percentage_change(previous_month[:expenses], current_month[:expenses]),
      profit_change: calculate_percentage_change(previous_month[:profit], current_month[:profit]),
      orders_change: calculate_percentage_change(previous_month[:orders_count], current_month[:orders_count])
    }
  end
  
  def calculate_percentage_change(old_value, new_value)
    return 0 if old_value == 0
    ((new_value - old_value) / old_value.to_f * 100).round(2)
  end
end
