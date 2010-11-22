# -*- coding: utf-8 -*-
# == Schema Information
# Schema version: 20091016144057
#
# Table name: invoices
#
#  id                  :integer(4)      not null, primary key
#  client_id           :integer(4)
#  date                :date
#  number              :string(255)
#  extra_info          :text
#  terms               :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  discount_text       :string(255)
#  discount_percent    :integer(4)
#  draft               :boolean(1)
#  type                :string(255)
#  frequency           :integer(4)
#  invoice_template_id :integer(4)
#  status              :integer(4)      default(1)
#  due_date            :date
#  use_bank_account    :boolean(1)      default(TRUE)
#

class Invoice < ActiveRecord::Base

  unloadable

  # Invoice statuses
  STATUS_NOT_SENT = 1
  STATUS_SENT     = 5
  STATUS_CLOSED   = 9

  # Default tax %
  TAX = 18

  STATUS_LIST = { STATUS_NOT_SENT=>'Not sent', STATUS_SENT=>'Sent', STATUS_CLOSED=>'Closed' }


  has_many :invoice_lines, :dependent => :destroy, :after_add => :save, :after_remove => :save
  belongs_to :client
  validates_presence_of :client, :date

  accepts_nested_attributes_for :invoice_lines,
    :allow_destroy => true,
    :reject_if => proc { |attributes| attributes.all? { |_, value| value.blank? } }
  validates_associated :invoice_lines

  before_save :set_due_date

  def subtotal_without_discount
    total = Money.new(0)
    invoice_lines.each do |line|
      next if line.destroyed?
      total = total + line.total
    end
    total
  end

  def subtotal
    subtotal_without_discount - discount
  end

  def tax
    subtotal * (tax_percent / 100.0)
  end

  def withholding_tax
    subtotal * (self.client.project.company.withholding_tax_percent / 100.0)
  end

  def withholding_tax_percent
    self.client.project.company.withholding_tax_percent
  end

  def withholding_tax_name
    self.client.project.company.withholding_tax_name
  end

  def discount
    if discount_percent
      subtotal_without_discount * (discount_percent / 100.0)
    else
      Money.new(0)
    end
  end

  def total
    subtotal + tax - withholding_tax
  end

  def subtotal_eur
    "#{subtotal} €"
  end

  def due
    if terms.nil? or terms==0
      "#{terms_description}: #{due_date}"
    else
      "#{terms_description}"
    end
  end

  def pdf_name
    # i18n catalan ca-AD
    # remove_non_ascii "factura-#{number.gsub('/','')}-#{client.name.upcase.gsub(/\/|\.|\'/,'').strip.gsub(' ','_')}.pdf"
    "factura-#{number.gsub('/','')}.pdf"
  end

  def recipients
    Person.find(:all,:order=>'last_name ASC',:conditions => ["client_id = ? AND invoice_recipient = ?", client, true])
  end

  def self.last_number(project)
    i = InvoiceDocument.last(:order => "number", :include => [:client], :conditions => ["clients.project_id=? AND draft=?",project.id,false])
    i.number if i
  end

  def self.next_number(project)
    number = self.last_number(project)
    if number.nil?
      a = []
      num = 0
    else
      a = number.split('/')
      num = number.to_i
    end
    if a.size > 1
      a[1] =  sprintf('%03d', a[1].to_i + 1)
      return a.join("/")
    else
      return num + 1
    end
  end

  def sent?
    self.status > STATUS_NOT_SENT
  end

  def mark_closed
    update_attribute :status, STATUS_CLOSED
  end

  def mark_sent
    update_attribute :status, STATUS_SENT
  end

  def mark_not_sent
    update_attribute :status, STATUS_NOT_SENT
  end

  def closed?
    self.status == STATUS_CLOSED
  end


  def status_txt
    STATUS_LIST[self.status]
  end

  def terms_description
    terms_object.description
  end

  def payment_method
    if use_bank_account and client.bank_account
      ba = client.bank_account
      "Rebut domiciliat a #{ba[0..3]} #{ba[4..7]} ** ******#{ba[16..19]}"
    else
      ba = self.client.project.company.bank_account rescue ""
      "Pagament per transferència al compte #{ba[0..3]} #{ba[4..7]} #{ba[8..9]} #{ba[10..19]}"
    end
  end

  def <=>(oth)
    self.number <=> oth.number
  end

  def project
    self.client.project
  end

  def past_due?
    self.status < STATUS_CLOSED && due_date && due_date < Date.today
  end

  def currency
    client.currency.blank? ? "EUR" : client.currency
  end

  private

  def set_due_date
    self.due_date = terms_object.due_date
  end

  def terms_object
    Terms.new(self.terms, self.date)
  end

end
