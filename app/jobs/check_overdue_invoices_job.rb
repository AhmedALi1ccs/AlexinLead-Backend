class CheckOverdueInvoicesJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "Checking for overdue invoices..."
    
    # Update overdue status for all orders
    overdue_orders = Order.where('due_date < ? AND payment_status != ?', Date.current, 'received')
    
    overdue_orders.update_all(is_overdue: true)
    
    if overdue_orders.exists?
      total_overdue_amount = overdue_orders.sum('total_amount - payed')
      
      Rails.logger.warn "⚠️ Found #{overdue_orders.count} overdue invoices totaling #{total_overdue_amount} SAR"
      
      # Notify admins about overdue invoices
      notify_admins_of_overdue_invoices(overdue_orders.count, total_overdue_amount)
    else
      Rails.logger.info "✅ No overdue invoices found"
    end
  end
  
  private
  
  def notify_admins_of_overdue_invoices(count, amount)
    # This could send email notifications to admins
    Rails.logger.info "📧 Notifying admins: #{count} overdue invoices totaling #{amount} SAR"
  end
end
