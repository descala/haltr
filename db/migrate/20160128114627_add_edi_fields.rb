class AddEdiFields < ActiveRecord::Migration

  def up
    add_column :invoices, :order_date,        :date
    add_column :invoices, :contract_number,   :string
    add_column :clients,  :buyer_edi_code,    :string
    add_column :clients,  :receiver_edi_code, :string
  end

  def down
    remove_column :invoices, :order_date
    remove_column :invoices, :contract_number
    remove_column :clients,  :buyer_edi_code
    remove_column :clients,  :receiver_edi_code
  end

end
