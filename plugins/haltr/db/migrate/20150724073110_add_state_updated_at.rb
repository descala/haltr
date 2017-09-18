class AddStateUpdatedAt < ActiveRecord::Migration
  def change
    change_table :invoices do |t|
      t.datetime 'state_updated_at'
    end
  end
end
