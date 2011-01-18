class Event < ActiveRecord::Base
  unloadable

  validates_presence_of :name
  validates_presence_of :invoice_id
  belongs_to :user
  belongs_to :invoice

  def initialize(attributes=nil)
    super
  end

end
