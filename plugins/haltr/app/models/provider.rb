class Provider < ActiveRecord::Base

  # see http://collectiveidea.com/blog/archives/2015/07/30/bi-directional-and-self-referential-associations-in-rails/
  belongs_to :company
  belongs_to :company_provider, class_name: 'Company'

  after_create :create_inverse, unless: :has_inverse?
  after_destroy :destroy_inverses, if: :has_inverse?
  validate :cant_be_company_provider_of_self

  def create_inverse
    self.class.create(inverse_provider_options)
  end

  def destroy_inverses
    inverses.destroy_all
  end

  def has_inverse?
    self.class.exists?(inverse_provider_options)
  end

  def inverses
    self.class.where(inverse_provider_options)
  end

  def inverse_provider_options
    { company_provider_id: company_id, company_id: company_provider_id }
  end

  def cant_be_company_provider_of_self
    if company_id == company_provider_id
      errors.add(:company_providers, "can't be provider of self!")
    end
  end

end
