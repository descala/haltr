# encoding: utf-8
module PaymentsHelper

  def invoices_for_select(type=nil)
    cond = ARCondition.new
    if @payment.invoice
      cond << ["(clients.project_id = ? and state != 'closed') OR invoices.id=?", @project, @payment.invoice]
    else
      cond << ["clients.project_id = ? and state != 'closed'", @project]
    end
    cond << ["type = ?", type] if type
    InvoiceDocument.find(:all, :order => 'number DESC', :include => 'client', :conditions => cond.conditions).collect {|c| [ "#{c.number} #{c.total.to_s.rjust(10).gsub(' ','_')}€ #{c.client}", c.id ] }
  end


end
