class ClientOffice < ActiveRecord::Base

  unloadable

  belongs_to :client
  has_many :invoices, dependent: :nullify
  validates_presence_of :name

  CLIENT_FIELDS = %w( address address2 city province postalcode country email )

  CLIENT_FIELDS.each do |attr|
    define_method(attr) do
      read_attribute(attr).blank? ? client.send(attr) : read_attribute(attr)
    end
  end

end
