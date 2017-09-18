class RemoveDir3IdFromInvoices < ActiveRecord::Migration

  def up
    remove_column :invoices, :dir3_id
  end

  def down
    add_column :invoices, :dir3_id, :string
  end

end
