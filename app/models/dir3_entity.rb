class Dir3Entity < ActiveRecord::Base
  unloadable
  iso_country :country
  include CountryUtils

  def full_address?
    address.present? and
    postalcode.present? and
    city.present? and
    province.present? and
    country.present?
  end

end
