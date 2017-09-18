class AddReceiverContractReferenceToInvoices < ActiveRecord::Migration

  def change
    add_column :invoices, :receiver_contract_reference, :string
  end

end
