class InvoiceTemplatesController < InvoicesController

  T_COLS = ['client','date','frequency','terms','use_bank_account','invoice_lines','discount_text', 'discount_percent','extra_info']

  active_scaffold :invoice_template do |config|
    config.label='Recurring invoices'
    config.action_links.add "showit", {:type=>:record, :page=>true, :label=>"Show"}
    config.show.link = nil
    config.list.columns = ['client','subtotal_eur','date','frequency','invoice_lines','invoice_documents']
    config.create.columns = T_COLS
    config.update.columns = T_COLS
    config.show.columns = [] 
    config.columns[:invoice_documents].clear_link
    config.columns[:date].label = 'Next charge date'
    config.columns[:frequency].label = 'Frequency (Months)'
    config.columns[:client].form_ui = :select
  end
  
end
