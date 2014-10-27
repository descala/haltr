class Dir3Entity < ActiveRecord::Base
  unloadable
  iso_country :country
  include CountryUtils
end
