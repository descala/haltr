module PaymentsHelper

  def invoices_for_select
    InvoiceDocument.find(:all, :order => 'number', :include => 'client', :conditions => ["clients.project_id = ? and status < ? ", @project, Invoice::STATUS_CLOSED]).collect {|c| [ c.number, c.id ] }
  end

end
