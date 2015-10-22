class Dir3Entity < ActiveRecord::Base
  unloadable
  iso_country :country
  include CountryUtils

  validates_presence_of :code, :name
  validates_uniqueness_of :code

  def full_address?
    address.present? and
    postalcode.present? and
    city.present? and
    province.present? and
    country.present?
  end

  def code=(dir3_code)
    self[:code] = dir3_code.gsub(/ /,'')
  end

end
