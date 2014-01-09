class Event < ActiveRecord::Base
  unloadable

  validates_presence_of :name
  validates_presence_of :invoice_id
  belongs_to :user
  belongs_to :invoice

  after_create :update_invoice, :unless => Proc.new {|event| event.invoice.nil?}

  def to_s
    # TODO: log the origin of the REST event. i.e. "Sent by host4"
    str = l(name)
    if name == "validating_format" and invoice.transport == "email"
      str += " #{l(:by_mail_from, :email=>invoice.from)} "
    end
    if user and name != "by_email"
      str += " #{l(:by)} #{user.name}"
    elsif name == "by_email"
      str += " #{l(:by)} #{invoice.from}"
    end
    if info
      unless name == "accept" or name == "refuse" or name == "paid" # accept and refuse stores mail on info
        str += " (#{info})"
      end
    end
    str
  end

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

  def automatic?
    Event.automatic.include? name
  end

  def self.automatic
    events  = %w(bounced sent_notification delivered_notification registered_notification)
    events += %w(refuse_notification accept_notification paid_notification accept refuse)
    actions = %w(sending receiving validating_format validating_signature)
    actions.each do |a|
      events << "success_#{a}"
      events << "error_#{a}"
      events << "discard_#{a}"
    end
    events
  end

  private

  def update_invoice
    self.invoice.send(name) if automatic?
  end

end
