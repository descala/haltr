class AddStateToInvoices < ActiveRecord::Migration

  def self.up
    add_column :invoices, :state, :string
    begin
      InvoiceDocument.all.each do |i|
        if i.status == 5
          i.state="sent"
        elsif i.status == 9
          i.state="closed"
        else
          i.state="new"
        end
        i.save(:validate=>false)
      end
    rescue
      nil
    end
    remove_column :invoices, :status
  end

  def self.down
    remove_column :invoices, :state
    add_column :invoices, :status, :integer, :default => 1
  end

end
