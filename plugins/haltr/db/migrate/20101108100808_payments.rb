class Payments < ActiveRecord::Migration
  def self.up
    create_table "payments" do |t|
      t.integer  "invoice_id"
      t.integer  "project_id"
      t.integer  "amount_in_cents"
      t.date     "date"
      t.string   "payment_method"
      t.string   "reference"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :payments
  end
end
