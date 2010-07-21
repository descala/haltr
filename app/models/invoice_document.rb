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

class InvoiceDocument < Invoice

  unloadable

  belongs_to :invoice_template
  validates_presence_of :number
  validates_uniqueness_of :number

  def self.find_due_dates
    find_by_sql "select due_date, invoices.id, count(*) as invoice_count from invoices, clients where type='InvoiceDocument' and client_id = clients.id and status = #{Invoice::STATUS_SENT} and bank_account and use_bank_account group by due_date"
  end

  def label
    if self.draft
      "Esborrany de factura"
    else
      "Factura"
    end
  end

  def to_label
    "#{number}"
  end

  def self.find_not_sent
    find :all, :conditions => ["status = ? and draft != ?", Invoice::STATUS_NOT_SENT, 1 ]
  end

  def self.count_not_sent
    count :all, :conditions => ["status = ? and draft != ?", Invoice::STATUS_NOT_SENT, 1 ]
  end


end
