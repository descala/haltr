class AddSepaMandates < ActiveRecord::Migration
  def up
    add_column :clients, :sepa_type, :string
  end

  def down
    remove_column :clients, :sepa_type
  end
end
