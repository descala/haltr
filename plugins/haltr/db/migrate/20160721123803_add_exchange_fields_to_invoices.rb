class AddExchangeFieldsToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :exchange_rate, :float
    add_column :invoices, :exchange_date, :date
  end

  def down
    remove_column :invoices, :exchange_rate
    remove_column :invoices, :exchange_date
  end

end
