module PaymentsHelper

  def invoices_for_select
    if @payment.invoice
      conditions = ["(clients.project_id = ? and status < ?) OR invoices.id=?", @project, Invoice::STATUS_CLOSED, @payment.invoice]
    else
      conditions = ["clients.project_id = ? and status < ?", @project, Invoice::STATUS_CLOSED]
    end
    InvoiceDocument.find(:all, :order => 'number DESC', :include => 'client', :conditions => conditions).collect {|c| [ "#{c.number} #{c.total.to_s.rjust(10).gsub(' ','_')}€ #{c.client}", c.id ] }
  end

end
