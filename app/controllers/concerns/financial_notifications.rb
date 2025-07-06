module FinancialNotifications
  extend ActiveSupport::Concern
  
  def generate_financial_notifications
    notifications = []
    current_month = Date.current
    
    # Check break-even status
    revenue = calculate_monthly_revenue(current_month.month, current_month.year)
    expenses = calculate_monthly_expenses(current_month.month, current_month.year)
    
    if revenue >= expenses && revenue > 0
      notifications << {
        type: 'success',
        title: 'Break-even Achieved! 🎉',
        message: "This month's revenue (#{format_currency(revenue)}) has exceeded expenses (#{format_currency(expenses)})",
        priority: 'high'
      }
    end
    
    # Check monthly target progress
    target = MonthlyTarget.for_current_month
    if target && revenue >= target.gross_earnings_target
      notifications << {
        type: 'success', 
        title: 'Monthly Target Achieved! 🎯',
        message: "Congratulations! You've reached this month's target of #{format_currency(target.gross_earnings_target)}",
        priority: 'high'
      }
    end
    
    # Check overdue receivables
    ar_summary = calculate_accounts_receivable_summary
    if ar_summary[:overdue] > 0
      notifications << {
        type: 'warning',
        title: 'Overdue Invoices Alert ⚠️',
        message: "You have #{format_currency(ar_summary[:overdue])} in overdue receivables",
        priority: 'medium'
      }
    end
    
    # Check pending expenses
    pending_expenses = Expense.pending.sum(:amount)
    if pending_expenses > 0
      notifications << {
        type: 'info',
        title: 'Pending Expense Approvals',
        message: "#{format_currency(pending_expenses)} in expenses pending approval",
        priority: 'low'
      }
    end
    
    notifications
  end
end
