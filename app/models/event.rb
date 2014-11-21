class Event < ActiveRecord::Base
  unloadable

  validates_presence_of :name
  validates_presence_of :project_id
  belongs_to :project
  belongs_to :user
  belongs_to :invoice
  belongs_to :client
  has_many :audits, :class_name=>'Audited::Adapters::ActiveRecord::Audit'

  before_validation :set_project_if_nil
  after_create :update_invoice, :unless => Proc.new {|event| event.invoice.nil?}

  ### redmine activity ###
  acts_as_event :type => 'info_event',
    :title => Proc.new {|e| "#{I18n.t(e.invoice.type)} #{e.invoice.number} (#{I18n.t('state_'+e.invoice.state)})" },
    :url => Proc.new {|e| {:controller=>'invoices', :action=>'show', :id=>e.invoice_id} },
    :datetime => :created_at,
    :author => :user_id
  acts_as_activity_provider :type => 'info_events',
    :author_key => :user_id,
    :permission => :general_use,
    :timestamp => "#{Event.table_name}.created_at",
    :find_options => {:include => [:user, {:invoice => :project}],
                      :conditions => "events.name in ('success_sending')"}

  acts_as_event :type => 'error_event',
    :title => Proc.new {|e| "#{I18n.t(e.invoice.type)} #{e.invoice.number} (#{I18n.t('state_'+e.invoice.state)})" },
    :url => Proc.new {|e| {:controller=>'invoices', :action=>'show', :id=>e.invoice_id} },
    :datetime => :created_at,
    :author => :user_id
  acts_as_activity_provider :type => 'error_events',
    :author_key => :user_id,
    :permission => :general_use,
    :timestamp => "#{Event.table_name}.created_at",
    :find_options => {:include => [:user, {:invoice => :project}],
                      :conditions => "events.name in ('error_sending','discard_sending')"}
  ########################

  serialize :info

  def to_s
    str = l(name)
    str << " #{l(:by)} #{user.name}" if user
    str
  end

  def description
    str = ""
    if class_for_send
      str << l(class_for_send)
    else
      str << 'client channel: '
      #TODO: this slows down this page...
      str << ExportChannels.l(self.invoice.client.invoice_format) rescue ''
    end
    str << " - " unless str.blank?
    str << l(name)
    str
  end

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

  # automatic events can change invoice status (after_create :update_invoice)
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

  def file
    Haltr::Utils.decompress(read_attribute(:file))
  end

  def file=(s)
    if s and s.size > 0
      write_attribute(:file, Haltr::Utils.compress(s))
    end
  end

  %w(notes class_for_send md5 final_md5 error backtrace).each do |c|
    src = <<-END_SRC
      def #{c}
        info[:#{c}] rescue nil
      end

      def #{c}=(v)
        self.info ||= {}
        self.info[:#{c}] = v
      end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def set_project_if_nil
    if project.nil?
      self.project = invoice.project if invoice
      self.project = client.project  if client
    end
  end

  private

  def update_invoice
    self.invoice.send(name) if automatic?
  end

end
