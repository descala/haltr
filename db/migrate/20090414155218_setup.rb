# -*- coding: utf-8 -*-
class Setup < ActiveRecord::Migration
  def self.up

    begin
      create_table "clients" do |t|
        t.string   "taxcode", :limit => 9
        t.string   "name"
        t.string   "address1"
        t.string   "address2"
        t.string   "city"
        t.string   "province"
        t.string   "postalcode"
        t.string   "country", :default => "España"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "bank_account", :limit => 24
      end

      create_table "invoice_lines" do |t|
        t.integer  "invoice_id"
        t.integer  "quantity"
        t.string   "description", :limit => 512
        t.integer  "price_in_cents"
        t.datetime "created_at"
        t.datetime "updated_at"
      end

      create_table "invoices" do |t|
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

      create_table "people" do |t|
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

    rescue Exception
      # Migration from previous version
    end


  end

  def self.down
    drop_table :clients
    drop_table :invoice_lines
    drop_table :invoices
    drop_table :people
  end
end
