# haltr 

ActiveRecord::Schema.define(:version => 20110926143226) do

  create_table "clients", :force => true do |t|
    t.string   "taxcode",             :limit => 20
    t.string   "name"
    t.string   "address"
    t.string   "address2"
    t.string   "city"
    t.string   "province"
    t.string   "postalcode"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bank_account",        :limit => 24
    t.integer  "project_id"
    t.string   "email"
    t.string   "language"
    t.string   "currency"
    t.string   "invoice_format"
    t.string   "website"
    t.integer  "company_id"
    t.boolean  "allowed"
    t.string   "hashid"
    t.string   "terms"
    t.integer  "payment_method"
    t.string   "iban"
    t.string   "bic"
    t.string   "payment_method_text"
  end

  create_table "companies", :force => true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.string   "taxcode",        :limit => 20
    t.string   "address"
    t.string   "city"
    t.string   "postalcode"
    t.string   "province"
    t.string   "website"
    t.string   "email"
    t.string   "bank_account",   :limit => 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country"
    t.string   "currency"
    t.string   "public",                       :default => "private"
    t.string   "invoice_format"
    t.string   "iban"
    t.string   "bic"
  end

  create_table "invoice_lines", :force => true do |t|
    t.integer  "invoice_id"
    t.decimal  "quantity",                   :precision => 18, :scale => 9
    t.string   "description", :limit => 512
    t.decimal  "price",                      :precision => 18, :scale => 9
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency",                                                  :default => "EUR"
    t.integer  "unit",                                                      :default => 1
  end

  add_index "invoice_lines", ["invoice_id"], :name => "index_invoice_lines_on_invoice_id"

  create_table "invoices", :force => true do |t|
    t.integer  "client_id"
    t.date     "date"
    t.string   "number"
    t.text     "extra_info"
    t.string   "terms"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "discount_text"
    t.integer  "discount_percent",    :default => 0
    t.string   "type"
    t.integer  "frequency"
    t.integer  "invoice_template_id"
    t.date     "due_date"
    t.integer  "import_in_cents"
    t.string   "ponumber"
    t.string   "currency"
    t.integer  "payment_method"
    t.string   "state"
    t.string   "invoice_format"
    t.integer  "project_id"
    t.string   "transport"
    t.string   "from"
    t.integer  "total_in_cents"
    t.integer  "amend_id"
    t.string   "payment_method_text"
    t.boolean  "has_been_read",       :default => true
  end

  add_index "invoices", ["client_id"], :name => "index_invoices_on_client_id"
  add_index "invoices", ["date"], :name => "index_invoices_on_date"
  add_index "invoices", ["number"], :name => "index_invoices_on_number"
  add_index "invoices", ["project_id"], :name => "index_invoices_on_project_id"
  add_index "invoices", ["type"], :name => "index_invoices_on_type"

  create_table "payments", :force => true do |t|
    t.integer  "invoice_id"
    t.integer  "project_id"
    t.integer  "amount_in_cents"
    t.date     "date"
    t.string   "payment_method"
    t.string   "reference"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "taxes", :force => true do |t|
    t.integer "company_id"
    t.integer "invoice_line_id"
    t.string  "name"
    t.float   "percent"
    t.boolean "default"
  end

  add_index "taxes", ["company_id"], :name => "index_taxes_on_company_id"
  add_index "taxes", ["invoice_line_id"], :name => "index_taxes_on_invoice_line_id"

end
