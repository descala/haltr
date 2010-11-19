class AddPonumberToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :ponumber, :string
  end

  def self.down
    remove_column :invoices, :ponumber
  end

end
