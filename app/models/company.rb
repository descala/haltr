class Company < ActiveRecord::Base

  unloadable

  belongs_to :project
  has_many :clients, :dependent => :nullify
  validates_presence_of :name, :project_id, :email
  validates_length_of :taxcode, :maximum => 20
  validates_uniqueness_of :taxcode
  validates_length_of :postalcode, :is => 5
  validates_numericality_of :bank_account, :allow_nil => true, :unless => Proc.new {|company| company.bank_account.blank?}
  validates_length_of :bank_account, :maximum => 20
  validates_inclusion_of :currency, :in  => Money::Currency::TABLE.collect {|k,v| v[:iso_code] }
  acts_as_attachable :view_permission => :free_use,
                     :delete_permission => :free_use
  after_save :update_linked_clients

  def initialize(attributes=nil)
    super
    self.withholding_tax_name ||= "IRPF"
    self.currency ||= Money.default_currency.iso_code
    self.attachments ||= []
  end

  def <=>(oth)
    self.name <=> oth.name
  end

  def first_name
    name.split(" ").first
  end

  def last_name
    ln = name.split(" ")
    ln.shift
    ln.join(" ")
  end

  def currency=(v)
    write_attribute(:currency,v.upcase)
  end

  def public?
    self.public == "public"
  end

  def semipublic?
    self.public == "semipublic"
  end

  def private?
    self.public == "private"
  end

  def companies_with_link_requests
    self.clients.collect { |c|
      next unless c.project and c.project.company
      c.project.company if c.allowed.nil?
    }.compact
  end

  def taxcode=(tc)
    # taxcode is used to retrieve logo on xhtml when transforming to PDF,
    # some chars will make logo retrieval fail (i.e. spaces)
    write_attribute(:taxcode,tc.to_s.gsub(/\W/,''))
  end

  private

  def update_linked_clients
    self.clients.each do |client|
      if self.private?
        client.company=nil
        client.allowed=nil
      end
      client.save
    end
  end

end
