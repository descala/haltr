class AddMoreEdiFields < ActiveRecord::Migration

  def up
    add_column :clients, :payer_edi_code, :string
    add_column :clients, :destination_edi_code, :string
    add_column :client_offices, :destination_edi_code, :string
  end

  def down
    remove_column :clients, :payer_edi_code
    remove_column :clients, :destination_edi_code
    remove_column :client_offices, :destination_edi_code
  end

end
