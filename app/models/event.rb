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

  serialize :info


  def to_s
    str = l(name)
    str += " #{l(:by)} #{user.name}" if user
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

  %w(notes md5 final_md5).each do |c|
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

  private

  def update_invoice
    self.invoice.send(name) if automatic?
  end

end
