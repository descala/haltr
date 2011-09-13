class RemoveTaxesFromInvoices < ActiveRecord::Migration

  def self.up
    if Invoice.count > 0
      say "-----------------------------------------------------------------------------------------------------"
      say "Please BACKUP YOUR DATABASE before continue! Irreversible changes to the invoices table will be made."
      say "-----------------------------------------------------------------------------------------------------"
      say "continue?(y/N)"
      confirmation = $stdin.gets.strip
      raise "Migration aborted by user" unless confirmation == "y"
    end
    say_with_time "Migrating invoices, this may take a while..." do
      tax_names = {"es" => "IVA", "fr" => "TVA" }
      Invoice.all.each do |invoice|
        if invoice.tax_percent and invoice.tax_percent > 0
          invoice.invoice_lines.each do |il|
            il.taxes << Tax.new(:name => (tax_names[invoice.company.country] || "VAT"), :percent => invoice.tax_percent)
          end
        end
        if invoice.apply_withholding_tax and invoice.company.withholding_tax_percent
          tax_percent = invoice.company.withholding_tax_percent * -1
          invoice.invoice_lines.each do |il|
            il.taxes << Tax.new(:name => "IRPF", :percent => tax_percent)
          end
        end
        invoice.save(false) # to trigger update_imports method and update invoice imports
      end
    end
    remove_column :invoices, :withholding_tax_in_cents
    remove_column :invoices, :apply_withholding_tax
    remove_column :invoices, :tax_percent
    remove_column :companies, :withholding_tax_name
    remove_column :companies, :withholding_tax_percent
  end

  def self.down
    add_column :invoices, :withholding_tax_in_cents, :integer
    add_column :invoices, :apply_withholding_tax, :boolean
    add_column :invoices, :tax_percent, :float
    add_column :companies, :withholding_tax_name, :string
    add_column :companies, :withholding_tax_percent, :integer
  end

end
