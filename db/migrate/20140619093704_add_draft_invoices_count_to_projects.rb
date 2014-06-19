class AddDraftInvoicesCountToProjects < ActiveRecord::Migration

  def self.up
    add_column :projects, :draft_invoices_count, :integer, :default => 0

    #Project.reset_column_information
    Project.all.each do |p|
      Project.update_counters p.id,
        :invoices_count          => p.invoices.count,
        :issued_invoices_count   => p.issued_invoices.count,
        :received_invoices_count => p.received_invoices.count,
        :invoice_templates_count => p.invoice_templates.count,
        :draft_invoices_count    => p.draft_invoices.count
    end
  end

  def self.down
    remove_column :projects, :draft_invoices_count
  end

end
