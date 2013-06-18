# encoding: utf-8
module PaymentsHelper

  def invoices_for_select
    if @payment.invoice
      cond = ["(clients.project_id = ? and state != 'closed') OR invoices.id=?", @project, @payment.invoice]
    else
      cond = ["clients.project_id = ? and state != 'closed'", @project]
    end
    InvoiceDocument.find(:all, :order => 'number DESC', :include => 'client', :conditions => cond).collect do |c|
      [ "#{c.number} #{c.total.to_s.rjust(10).gsub(' ','_')}€ #{c.client}", c.id ]
    end
  end

  def n19_fix(string,n=40)
    string.to_ascii[0..n-1].upcase.ljust(n)
  end

end
