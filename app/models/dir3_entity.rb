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
    self[:code] = dir3_code.gsub(/ /,'') rescue nil
  end

  # creates a Dir3Entity from hash if it does not exist (with same code)
  # adds it to external_company with specified role if exits
  def self.new_from_hash(hash_attributes, external_company_taxcode=nil, role=nil)
    code = hash_attributes[:code]
    dir3 = Dir3Entity.find_by_code code
    unless dir3
      # translate country (ESP ==> es)
      hash_attributes[:country] =
        SunDawg::CountryIsoTranslater.translate_standard(
          hash_attributes[:country], 'alpha3', 'alpha2'
      ).downcase rescue hash_attributes[:country]

      dir3 = Dir3Entity.new(hash_attributes)
      dir3.save!
    end
    ec = ExternalCompany.find_by_taxcode(external_company_taxcode)
    if ec
      case role
      when '01'
        unless ec.oficines_comptables =~ /#{code}/
          if ec.oficines_comptables.blank?
            ec.update_attribute :oficines_comptables, code
          else
            ec.update_attribute :oficines_comptables, "#{ec.oficines_comptables},#{code}"
          end
        end
      when '02'
        unless ec.organs_gestors =~ /#{code}/
          if ec.organs_gestors.blank?
            ec.update_attribute :organs_gestors, code
          else
            ec.update_attribute :organs_gestors, "#{ec.organs_gestors},#{code}"
          end
        end
      when '03'
        unless ec.unitats_tramitadores =~ /#{code}/
          if ec.unitats_tramitadores.blank?
            ec.update_attribute :unitats_tramitadores, code
          else
            ec.update_attribute :unitats_tramitadores, "#{ec.unitats_tramitadores},#{code}"
          end
        end
      when '04'
        unless ec.organs_proponents =~ /#{code}/
          if ec.organs_proponents.blank?
            ec.update_attribute :organs_proponents, code
          else
            ec.update_attribute :organs_proponents, "#{ec.organs_proponents},#{code}"
          end
        end
      else
        # unknown role
      end
    end
  rescue ActiveRecord::RecordInvalid
    raise $! if Rails.env == 'test'
  end

end
