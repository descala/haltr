class Event < ActiveRecord::Base
  unloadable

  validates_presence_of :name
  validates_presence_of :invoice_id
  belongs_to :user
  belongs_to :invoice
  delegate :project, :to => :invoice, :allow_nil => true

  after_create :update_invoice, :unless => Proc.new {|event| event.invoice.nil?}

  acts_as_event :title => Proc.new {|e| "#{I18n.t(e.invoice.type)} #{e.invoice.number}" },
                :url => Proc.new {|e| {:controller=>'invoices', :action=>'show', :id=>e.invoice} },
                :datetime => :created_at,
                :author => :user_id,
                :description => :to_s

  acts_as_activity_provider :type => 'events',
                            :author_key => :user_id,
                            :permission => :general_use,
                            :timestamp => "#{Event.table_name}.created_at",
                            :find_options => {:include => [:user, {:invoice => :project}]}


  def to_s
    # TODO: log the origin of the REST event. i.e. "Sent by host4"
    str = l(name)
    if name == "email" and invoice.transport == "email"
      str += " #{l(:by_mail_from, :email=>invoice.from)} "
    elsif user
      str += " #{l(:by)} #{user.name}"
    end
    if info
      unless name =~/_refuse_notification|_accept_notification|_paid_notification/ or
        name == "paid" # refuse/accept_notifications store mail on info
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
