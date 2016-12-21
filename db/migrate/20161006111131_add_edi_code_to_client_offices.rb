class AddEdiCodeToClientOffices < ActiveRecord::Migration

  def up
    add_column :client_offices, :edi_code, :string
  end

  def down
    remove_column :client_offices, :edi_code
  end

end
