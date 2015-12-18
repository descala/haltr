class AddPartiallyAmendedIdIndex < ActiveRecord::Migration

  def up
    add_index :invoices, :partially_amended_id
  end

  def down
    remove_index :invoices, :partially_amended_id
  end

end
