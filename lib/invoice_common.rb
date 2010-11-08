module InvoiceCommon

  unloadable
  def showit
    find_invoice
    @invoices_not_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_NOT_SENT]).sort
    @invoices_sent = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_SENT]).sort
    @invoices_closed = InvoiceDocument.find(:all,:conditions => ["client_id = ? and status = ?",@client.id,Invoice::STATUS_CLOSED]).sort
    render :template => "invoices/showit"
  end
  
  private
  
  def find_invoice
    @invoice=Invoice.find params[:id]
    if @invoice
      @client=@invoice.client
      @lines=@invoice.invoice_lines
    end
  end
  
end
