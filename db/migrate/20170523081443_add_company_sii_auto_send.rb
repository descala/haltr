class AddCompanySiiAutoSend < ActiveRecord::Migration
  def change
    add_column :companies, :sii_auto_send, :boolean
  end
end
