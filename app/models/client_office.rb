class ClientOffice < ActiveRecord::Base

  unloadable

  belongs_to :client
  delegate :project, to: :client
  has_many :invoices, dependent: :nullify
  validates_presence_of :name, :client_id
  validate :edi_code_is_unique_in_project

  iso_country :country

  CLIENT_FIELDS = %w( address address2 city province postalcode country email
  name destination_edi_code edi_code )

  CLIENT_FIELDS.each do |attr|
    define_method(attr) do
      (client and read_attribute(attr).blank?) ? client.send(attr) : read_attribute(attr)
    end
  end

  def to_s
    name.blank? ? client.to_s : name
  end

  def full_address
    addr = address
    addr += "\n#{address2}" if address2.present?
    addr
  end

  def country_alpha3
    country
  end

  def edi_code_is_unique_in_project
    if edi_code.present?
      project.client_offices.each do |co|
        next unless co.edi_code.to_s.chomp.casecmp(edi_code.to_s.chomp) == 0
        next if co.eql?(self)
        errors.add(:edi_code, :taken)
        return
      end
      project.clients.each do |c|
        next unless c.edi_code.to_s.chomp.casecmp(edi_code.to_s.chomp) == 0
        next if c.eql?(client)
        errors.add(:edi_code, :taken)
        return
      end
    end
  end

end
