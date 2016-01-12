class AddEdiCodes < ActiveRecord::Migration

  def up
    add_column :companies, :edi_code, :string
    add_column :clients,   :edi_code, :string
  end

  def down
    remove_column :companies, :edi_code
    remove_column :clients,   :edi_code
  end

end
