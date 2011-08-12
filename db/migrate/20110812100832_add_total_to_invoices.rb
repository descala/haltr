class AddTotalToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :total_in_cents, :integer
    # trigger callback to calculate total_in_cents
    say_with_time("Calculating invoice totals... this may take a while") do
      IssuedInvoice.all.each do |invoice|
        invoice.save(false)
      end
      InvoiceTemplate.all.each do |template|
        template.save(false)
      end
    end
  end

  def self.down
    remove_column :invoices, :total_in_cents
  end

end
