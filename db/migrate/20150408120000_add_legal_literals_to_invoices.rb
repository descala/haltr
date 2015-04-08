class AddLegalLiteralsToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :legal_literals, :string
  end

  def down
    remove_column :invoices, :legal_literals
  end

end
