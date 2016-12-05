class CompanyOffice < ActiveRecord::Base

  unloadable

  belongs_to :company
  delegate :project, to: :company
  has_many :invoices, dependent: :nullify
  validates_presence_of :company_id
  iso_country :country

  COMPANY_FIELDS = %w( address city province postalcode country )

  COMPANY_FIELDS.each do |attr|
    define_method(attr) do
      (company and read_attribute(attr).blank?) ? company.send(attr) : read_attribute(attr)
    end
  end

  def country_alpha3
    country
  end

end

