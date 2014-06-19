class FixProjectCounters < ActiveRecord::Migration

  def self.up
    #Project.reset_column_information
    Project.all.each do |p|
      p.update_attributes(
        :invoices_count          => p.invoices.count,
        :issued_invoices_count   => p.issued_invoices.where(:type=>'IssuedInvoice').count,
        :received_invoices_count => p.received_invoices.count,
        :invoice_templates_count => p.invoice_templates.count,
        :draft_invoices_count    => p.draft_invoices.count
      )
    end
  end

  def self.down
  end

end
