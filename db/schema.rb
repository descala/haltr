# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091016144057) do

  create_table "clients", :force => true do |t|
    t.string   "taxcode",      :limit => 9
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "province"
    t.string   "postalcode"
    t.string   "country",                    :default => "España"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bank_account", :limit => 24
  end

  create_table "invoice_lines", :force => true do |t|
    t.integer  "invoice_id"
    t.float    "quantity"
    t.string   "description",    :limit => 512
    t.integer  "price_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "client_id"
    t.date     "date"
    t.string   "number"
    t.text     "extra_info"
    t.string   "terms"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "discount_text"
    t.integer  "discount_percent"
    t.boolean  "draft",               :default => false
    t.string   "type"
    t.integer  "frequency"
    t.integer  "invoice_template_id"
    t.integer  "status",              :default => 1
    t.date     "due_date"
    t.boolean  "use_bank_account",    :default => true
  end

  create_table "people", :force => true do |t|
    t.integer  "client_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone_office"
    t.string   "phone_mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "invoice_recipient", :default => false
    t.boolean  "report_recipient",  :default => false
  end

  create_table "settings", :force => true do |t|
    t.string   "name",       :limit => 50, :default => "", :null => false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
