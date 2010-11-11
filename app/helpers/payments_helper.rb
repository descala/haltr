module PaymentsHelper

  def invoices_for_select
    InvoiceDocument.find(:all, :order => 'number DESC', :include => 'client', :conditions => ["clients.project_id = ? and status < ? ", @project, Invoice::STATUS_CLOSED]).collect {|c| [ "#{c.number} #{c.total.to_s.rjust(10).gsub(' ','_')}€ #{c.client}", c.id ] }
  
  end

end
