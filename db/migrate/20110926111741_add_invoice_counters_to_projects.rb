class AddInvoiceCountersToProjects < ActiveRecord::Migration

  def self.up
    add_column :projects, :invoices_count,          :integer, :default => 0
    add_column :projects, :issued_invoices_count,   :integer, :default => 0
    add_column :projects, :received_invoices_count, :integer, :default => 0
    add_column :projects, :invoice_templates_count, :integer, :default => 0

    #Project.reset_column_information
    Project.all.each do |p|
      Project.update_counters p.id,
        :invoices_count          => p.invoices.length,
        :issued_invoices_count   => p.issued_invoices.length,
        :received_invoices_count => p.received_invoices.length,
        :invoice_templates_count => p.invoice_templates.length
    end
  end

  def self.down
    remove_column :projects, :invoices_count
    remove_column :projects, :issued_invoices_count
    remove_column :projects, :received_invoices_count
    remove_column :projects, :invoice_templates_count
  end

end
