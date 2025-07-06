require 'csv'
class Api::V1::FinanceController < ApplicationController
  before_action :authorize_admin!
  
  def overview
    month = params[:month]&.to_i || Time.current.month
    year = params[:year]&.to_i || Time.current.year
    date_range = Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
    
    # Generate recurring expenses for the month if not already generated
    Expense.generate_recurring_expenses_for_month(month, year)
    
    # Financial calculations
    gross_earnings = calculate_gross_earnings(date_range)
    total_expenses = calculate_total_expenses(date_range)
    net_income = gross_earnings - total_expenses
    
    # Targets and break-even
    monthly_target = MonthlyTarget.find_by(month: month, year: year)
    break_even_achieved = net_income >= 0
    
    # Profit sharing
    financial_settings = FinancialSetting.current
    profit_shares = financial_settings.calculate_shares(net_income)
    
    # Accounts Receivable
    accounts_receivable = calculate_accounts_receivable
    
    # Gross expectations from upcoming orders
    gross_expectations = calculate_gross_expectations
    
    render json: {
      period: { month: month, year: year },
      gross_earnings: gross_earnings,
      total_expenses: total_expenses,
      net_income: net_income,
      
      expense_breakdown: {
        labor: Expense.by_type_for_month('labor', month, year),
        transportation: Expense.by_type_for_month('transportation', month, year),
        lunch: Expense.by_type_for_month('lunch', month, year),
        others: Expense.by_type_for_month('others', month, year)
      },
      
      monthly_target: monthly_target ? serialize_monthly_target_progress(monthly_target, gross_earnings, total_expenses) : nil,
      
      profit_sharing: {
        settings: serialize_financial_settings(financial_settings),
        shares: profit_shares
      },
      
      accounts_receivable: accounts_receivable,
      gross_expectations: gross_expectations,
      
      notifications: generate_notifications(gross_earnings, total_expenses, monthly_target, break_even_achieved)
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
      
      expenses = Expense.approved.where(
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
  
  def dashboard_summary
    # For main dashboard integration
    current_month = Date.current
    accounts_receivable = calculate_accounts_receivable
    gross_expectations = calculate_gross_expectations
    
    render json: {
      accounts_receivable: accounts_receivable,
      gross_expectations: gross_expectations,
      current_month_summary: {
        gross_earnings: calculate_gross_earnings(current_month.beginning_of_month..current_month.end_of_month),
        total_expenses: calculate_total_expenses(current_month.beginning_of_month..current_month.end_of_month)
      }
    }
  end
  
  def set_monthly_target
    month = params[:month].to_i
    year = params[:year].to_i
    
    target = MonthlyTarget.find_or_initialize_by(month: month, year: year)
    target.assign_attributes(monthly_target_params)
    target.created_by = current_user
    
    if target.save
      render json: {
        message: 'Monthly target set successfully',
        target: serialize_monthly_target(target)
      }
    else
      render json: {
        error: 'Failed to set monthly target',
        errors: target.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def profit_sharing_settings
    settings = FinancialSetting.current
    
    if request.patch? || request.put?
      if settings.update(profit_sharing_params)
        render json: {
          message: 'Profit sharing settings updated successfully',
          settings: serialize_financial_settings(settings)
        }
      else
        render json: {
          error: 'Failed to update settings',
          errors: settings.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: { settings: serialize_financial_settings(settings) }
    end
  end
  def export_financial_report
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    csv_data = generate_financial_csv(start_date, end_date)

    # UTF-8 BOM required for Arabic to show properly in Excel
    bom = "\uFEFF"

    send_data bom + csv_data,
              filename: "financial_report_#{start_date}_to_#{end_date}.csv",
              type: 'text/csv; charset=utf-8'
  end

    
  private
  
  def calculate_gross_earnings(date_range)
    Order.where(created_at: date_range, payment_status: 'received').sum(:total_amount) || 0
  end
  
  def calculate_total_expenses(date_range)
    Expense.approved.where(expense_date: date_range).sum(:amount) || 0
  end
  
  def calculate_accounts_receivable
    unpaid_orders = Order.where(payment_status: ['not_received', 'partial'])
                        .where.not(order_status: 'cancelled')
    
    overdue_orders = unpaid_orders.where('due_date < ?', Date.current)
    due_this_week = unpaid_orders.where(due_date: Date.current..1.week.from_now)
    
    {
      total_amount: unpaid_orders.sum('total_amount - payed') || 0,
      orders_count: unpaid_orders.count,
      overdue: {
        amount: overdue_orders.sum('total_amount - payed') || 0,
        count: overdue_orders.count
      },
      due_this_week: {
        amount: due_this_week.sum('total_amount - payed') || 0,
        count: due_this_week.count
      },
      oldest_unpaid: unpaid_orders.order(:created_at).first&.created_at
    }
  end
  
  def calculate_gross_expectations
    # Confirmed orders that haven't started yet
    upcoming_orders = Order.where(order_status: 'confirmed')
                          .where('start_date > ?', Date.current)
    
    # Orders happening this month
    this_month_orders = Order.where(order_status: 'confirmed')
                            .where(start_date: Date.current.beginning_of_month..Date.current.end_of_month)
    
    {
      upcoming_revenue: upcoming_orders.sum(:total_amount) || 0,
      upcoming_count: upcoming_orders.count,
      this_month_expected: this_month_orders.sum(:total_amount) || 0,
      this_month_count: this_month_orders.count
    }
  end
  
  def generate_notifications(gross_earnings, total_expenses, monthly_target, break_even_achieved)
    notifications = []
    
    if break_even_achieved
      notifications << {
        type: 'success',
        message: 'Break-even achieved for this month! 🎉',
        icon: '✅'
      }
    end
    
    if monthly_target && monthly_target.target_achieved?(gross_earnings)
      notifications << {
        type: 'success',
        message: "Monthly target of #{monthly_target.gross_earnings_target} SAR achieved! 🎯",
        icon: '🎯'
      }
    end
    
    # Check overdue invoices
    overdue_ar = calculate_accounts_receivable[:overdue]
    if overdue_ar[:count] > 0
      notifications << {
        type: 'warning',
        message: "#{overdue_ar[:count]} overdue invoices totaling #{overdue_ar[:amount]} SAR",
        icon: '⚠️'
      }
    end
    
    notifications
  end
  
  def generate_financial_csv(start_date, end_date)
  settings = FinancialSetting.current

  CSV.generate(headers: true, force_quotes: true) do |csv|
    csv << ['Date', 'Type', 'Category', 'Amount', 'Description', 'Order ID',
            'Partner 1 Share', 'Partner 2 Share', 'Company Saving', 'Status']

    # Revenue rows
    Order.where(created_at: start_date..end_date, payment_status: 'received').each do |order|
      csv << [
        order.created_at.strftime('%Y-%m-%d'),
        'Revenue',
        'Order Payment',
        order.total_amount,
        order.location_name,        
        order.order_id,
        '', '', '',
        'Received'
      ]
    end

    # Expenses
    Expense.approved.where(expense_date: start_date..end_date).each do |expense|
      csv << [
        expense.expense_date.strftime('%Y-%m-%d'),
        'Expense',
        expense.expense_type,
        -expense.amount,
        expense.description,
        expense.order&.order_id || '',
        '', '', '',
        expense.status.humanize
      ]
    end

    # Profit sharing summary
    (start_date..end_date).group_by(&:beginning_of_month).each do |month_start, _|
      month = month_start.month
      year = month_start.year

      gross_earnings = calculate_gross_earnings(month_start..month_start.end_of_month)
      total_expenses = calculate_total_expenses(month_start..month_start.end_of_month)
      net_income = gross_earnings - total_expenses

      next if net_income <= 0

      shares = settings.calculate_shares(net_income)

      csv << [
        month_start.strftime('%Y-%m-%d'),
        'Profit Share',
        settings.partner_1_name,
        shares[:partner_1],
        "Monthly profit share for #{month_start.strftime('%B %Y')}",
        '',
        shares[:partner_1], '', '',
        'Calculated'
      ]

      csv << [
        month_start.strftime('%Y-%m-%d'),
        'Profit Share',
        settings.partner_2_name,
        shares[:partner_2],
        "Monthly profit share for #{month_start.strftime('%B %Y')}",
        '',
        '', shares[:partner_2], '',
        'Calculated'
      ]

      csv << [
        month_start.strftime('%Y-%m-%d'),
        'Company Saving',
        'Retained Earnings',
        shares[:company_saving],
        "Monthly company savings for #{month_start.strftime('%B %Y')}",
        '',
        '', '', shares[:company_saving],
        'Retained'
      ]
    end
  end
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
  
  def serialize_monthly_target(target)
    {
      id: target.id,
      month: target.month,
      year: target.year,
      gross_earnings_target: target.gross_earnings_target,
      estimated_fixed_expenses: target.estimated_fixed_expenses,
      estimated_variable_expenses: target.estimated_variable_expenses,
      break_even_point: target.break_even_point,
      notes: target.notes,
      created_by: target.created_by.full_name
    }
  end
  
  def serialize_monthly_target_progress(target, actual_revenue, actual_expenses)
    {
      **serialize_monthly_target(target),
      progress_percentage: target.progress_percentage(actual_revenue),
      break_even_achieved: target.break_even_achieved?(actual_revenue, actual_expenses),
      target_achieved: target.target_achieved?(actual_revenue)
    }
  end
  
  def serialize_financial_settings(settings)
    {
      partner_1_name: settings.partner_1_name,
      partner_1_percentage: settings.partner_1_percentage,
      partner_2_name: settings.partner_2_name,
      partner_2_percentage: settings.partner_2_percentage,
      company_saving_percentage: settings.company_saving_percentage
    }
  end
  
  def monthly_target_params
    params.require(:monthly_target).permit(:gross_earnings_target, :estimated_fixed_expenses, :estimated_variable_expenses, :notes)
  end
  
  def profit_sharing_params
    params.require(:financial_setting).permit(:partner_1_name, :partner_1_percentage, :partner_2_name, :partner_2_percentage, :company_saving_percentage)
  end
end