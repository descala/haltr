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

end
