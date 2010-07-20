class InvoicesController < ApplicationController

  include InvoiceCommon
  
  COLS = ['draft','client','date','number','terms','tax_percent','use_bank_account','invoice_lines','discount_text', 'discount_percent','extra_info']
  
  active_scaffold :invoice_document do |config|
    config.action_links.add "showit", {:type=>:record, :page=>true, :label=>"Show"}
    config.action_links.add "pdf", {:type=>:record, :page=>true, :label=>"PDF"}
    config.action_links.add "template", {:type=>:record, :page=>false, :label=>"Template"}
    config.show.link = nil
    config.list.columns = ['status','number','client','subtotal_eur','date','due_date','invoice_lines']
    config.create.columns = COLS
    config.update.columns = COLS
    config.show.columns = []
    config.columns[:client].form_ui = :select
  end

end 
