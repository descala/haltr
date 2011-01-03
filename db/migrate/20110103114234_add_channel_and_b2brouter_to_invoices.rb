class AddChannelAndB2brouterToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :channel, :string
    add_column :invoices, :b2brouter_url, :string
  end

  def self.down
    remove_column :invoices, :channel
    remove_column :invoices, :b2brouter_url
  end

end
