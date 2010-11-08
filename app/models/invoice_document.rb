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
  has_many :payments, :foreign_key => 'invoice_id' #, :dependent => :restrict #TODO: ok to set as destroy?
#  has_many :payments, :dependent => :destroy
  validates_presence_of :number
  validates_uniqueness_of :number

  def self.find_due_dates(project)
    find_by_sql "SELECT due_date, invoices.id, count(*) AS invoice_count FROM invoices, clients WHERE type='InvoiceDocument' AND client_id = clients.id AND clients.project_id = #{project.id} AND status = #{Invoice::STATUS_SENT} AND bank_account AND use_bank_account GROUP BY due_date"
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

  def self.find_not_sent(project)
    find :all, :include => [:client], :conditions => ["clients.project_id = ? and status = ? and draft != ?", project.id, Invoice::STATUS_NOT_SENT, 1 ]
  end

  def self.count_not_sent(project)
    count :all, :include => [:client], :conditions => ["clients.project_id = ? and status = ? and draft != ?", project.id, Invoice::STATUS_NOT_SENT, 1 ]
  end

  def total_paid
    paid=0
    self.payments.each do |payment|
      paid += payment.amount.dollars
    end
    Money.new(paid)
  end

  def unpaid
    total - total_paid
  end

end
