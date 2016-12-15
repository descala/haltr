class CompanyOffice < ActiveRecord::Base

  belongs_to :company
  delegate :project, to: :company
  has_many :invoices, dependent: :nullify
  validates_presence_of :company_id

  attr_protected :created_at, :updated_at
  include CountryUtils

  COMPANY_FIELDS = %w( address city province postalcode country )

  COMPANY_FIELDS.each do |attr|
    define_method(attr) do
      (company and read_attribute(attr).blank?) ? company.send(attr) : read_attribute(attr)
    end
  end

end

