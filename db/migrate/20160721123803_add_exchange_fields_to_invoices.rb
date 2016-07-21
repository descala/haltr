class AddExchangeFieldsToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :exchange_rate, :float
    add_column :invoices, :exchange_date, :date
    Invoice.where("currency != 'EUR'").each {|invoice|
      invoice.update_attribute(:exchange_rate, 1)
      invoice.update_attribute(:exchange_date, Date.today)
    }
  end

  def down
    remove_column :invoices, :exchange_rate
    remove_column :invoices, :exchange_date
  end

end
