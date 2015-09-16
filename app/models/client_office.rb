class ClientOffice < ActiveRecord::Base

  unloadable

  belongs_to :client
  validates_presence_of :name

end
