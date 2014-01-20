class AddMandates < ActiveRecord::Migration
  def change
    create_table :mandates do |t|
      t.string  :identifier
      t.string  :signature_date
      t.boolean :recurrent
      t.string  :end_date
      t.integer :client_id
      t.text    :signed_doc, :limit => 16777215

      t.timestamps
    end
  end
end
