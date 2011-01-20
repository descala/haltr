class Event < ActiveRecord::Base
  unloadable

  AUTOMATIC = %w(success_sending error_sending discard)

  validates_presence_of :name
  validates_presence_of :invoice_id
  belongs_to :user
  belongs_to :invoice

  after_create :update_invoice

  def initialize(attributes=nil)
    super
  end

  def to_s
    if automatic?
      "#{created_at} -- #{name} by b2brouter"
    else
      "#{created_at} -- #{name} by #{user.name}"
    end
  end

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

  def automatic?
    AUTOMATIC.include? name
  end

  private

  def update_invoice
    invoice.send(name) if automatic?
  end

end
