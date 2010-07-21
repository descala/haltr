module InvoicesHelper

  def status_column(invoice)
    if invoice.closed?
      link_to("Closed", {:action => :mark_not_sent, :id => invoice}, :style => 'color: blue;')
    elsif invoice.sent?
      link_to("Sent", {:action => :mark_closed, :id => invoice}, :style => 'color: green;')
    else
      link_to("New", :action => :mark_sent, :id => invoice)
    end
  end

  def clients_for_select
    Client.find(:all, :order => 'name', :conditions => ["project_id = ?", @project]).collect {|c| [ c.name, c.id ] }
  end

end
