class AddCommentsCountToInvoices < ActiveRecord::Migration

  def up
    add_column :invoices, :comments_count, :integer
  end

  def down
    remove_column :invoices, :comments_count
  end

end
