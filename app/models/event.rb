class Event < ActiveRecord::Base
  unloadable

  validates_presence_of :name
  validates_presence_of :invoice_id
  belongs_to :user
  belongs_to :invoice

  after_create :update_invoice

  def initialize(attributes=nil)
    super
  end

  def to_s
    str = "#{format_time created_at} -- "
    if !user
      # TODO: log the origin of the REST event. i.e. "Sent by host4"
      str += "#{l(name)}"
    else
      str += "#{l(name)} #{l(:by)} #{user.name}"
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
    events = %w(bounced delivered registered they_refuse they_accept paid_notification)
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
