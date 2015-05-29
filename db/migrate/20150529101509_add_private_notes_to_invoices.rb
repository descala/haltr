class AddPrivateNotesToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :private_notes, :text
  end

  def down
    remove_column :invoices, :private_notes
  end

end
