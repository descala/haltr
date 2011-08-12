class RemoveTaxesFromInvoices < ActiveRecord::Migration

  def self.up
    say "-----------------------------------------------------------------------------------------------------"
    say "Please BACKUP YOUR DATABASE before continue! Irreversible changes to the invoices table will be made."
    say "-----------------------------------------------------------------------------------------------------"
    say "continue?(y/N)"
    confirmation = $stdin.gets.strip
    raise "Migration aborted by user" unless confirmation == "y"
    say_with_time "Migrating invoices, this may take a while..." do
      tax_names = {"es" => "IVA", "fr" => "TVA" }
      Invoice.find(:all, :conditions => "tax_percent > 0").each do |invoice|
        if invoice.company.taxes.find_by_percent(invoice.tax_percent)
          invoice.taxes << invoice.company.taxes.find_by_percent(invoice.tax_percent)
        else
          invoice.taxes << Tax.new(:name => (tax_names[invoice.company.country] || "VAT"), :percent => invoice.tax_percent, :company => invoice.company)
        end
        invoice.save(false)
      end
      Invoice.find(:all, :conditions => [ "apply_withholding_tax = ?", true]).each do |invoice|
        tax_percent = invoice.company.withholding_tax_percent * -1
        if invoice.company.taxes.find_by_percent(tax_percent)
          invoice.taxes << invoice.company.taxes.find_by_percent(tax_percent)
        else
          invoice.taxes << Tax.new(:name => "IRPF", :percent => tax_percent, :company => invoice.company)
        end
        invoice.save(false)
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
