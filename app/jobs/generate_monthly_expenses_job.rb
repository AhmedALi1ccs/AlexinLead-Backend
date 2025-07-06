class GenerateMonthlyExpensesJob < ApplicationJob
  queue_as :default
  
  def perform(month = nil, year = nil)
    month ||= Date.current.month
    year ||= Date.current.year
    
    Rails.logger.info "Generating recurring expenses for #{Date::MONTHNAMES[month]} #{year}"
    
    begin
      RecurringExpense.generate_monthly_expenses_for(month, year)
      
      # Log the results
      generated_count = Expense.where(
        expense_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
      ).where.not(recurring_expense_id: nil).count
      
      Rails.logger.info "✅ Generated #{generated_count} recurring expenses for #{Date::MONTHNAMES[month]} #{year}"
      
      # Optionally send notification to admins
      notify_admins_of_generation(month, year, generated_count)
      
    rescue => e
      Rails.logger.error "❌ Failed to generate recurring expenses: #{e.message}"
      raise e
    end
  end
  
  private
  
  def notify_admins_of_generation(month, year, count)
    # This could send email notifications to admins
    # For now, just log it
    Rails.logger.info "📧 Notifying admins: #{count} recurring expenses generated for #{Date::MONTHNAMES[month]} #{year}"
  end
end
