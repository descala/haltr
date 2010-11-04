# -*- coding: utf-8 -*-
# == Schema Information
# Schema version: 20091016144057
#
# Table name: clients
#
#  id           :integer(4)      not null, primary key
#  taxcode      :string(9)
#  name         :string(255)
#  address1     :string(255)
#  address2     :string(255)
#  city         :string(255)
#  province     :string(255)
#  postalcode   :string(255)
#  country      :string(255)     default("España")
#  created_at   :datetime
#  updated_at   :datetime
#  bank_account :string(24)
#

# -*- coding: utf-8 -*-
class Client < ActiveRecord::Base

  unloadable

  has_many :invoices ##, :dependent => :nullify ## NO ESBORRAR CLIENTS
  has_many :people

  # TODO: only in Redmine
  belongs_to :project

  validates_presence_of :name, :taxcode
  validates_uniqueness_of :name, :taxcode
#  validates_length_of :name, :maximum => 30
#  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/

  def taxcode_type
    if taxcode.first.upcase>="A"
      return "CIF"
    else
      #comença per un número
      return "NIF"
    end
  end

  def bank_invoices(due_date)
    InvoiceDocument.find :all, :conditions => ["client_id = ? and status = ? and draft != ? and use_bank_account and due_date = ?", self, Invoice::STATUS_SENT, 1, due_date ]
  end

  def bank_invoices_total(due_date)
    a = Money.new 0
    bank_invoices(due_date).each { |i| a = i.total + a }
    a
  end

  def to_label
    name
  end

  alias :to_s :to_label

  def invoice_templates
    self.invoices.find(:all,:conditions=>["type=?","InvoiceTemplate"])
  end

  def invoice_documents
    self.invoices.find(:all,:conditions=>["type=?","InvoiceDocument"])
  end

end
