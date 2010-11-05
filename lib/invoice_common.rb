module InvoiceCommon

  unloadable
  def showit
    find_invoice
    render :template => "invoices/showit", :layout => 'invoice'
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
