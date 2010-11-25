class Person < ActiveRecord::Base

  unloadable

  belongs_to :client

  validates_presence_of :client, :first_name, :last_name, :email
  validates_uniqueness_of :email, :scope => :client_id

  def to_label
    "#{first_name} #{last_name}"
  end

  def phone
    if phone_office.blank? and phone_mobile.blank?
      nil
    elsif phone_office.blank?
      phone_mobile
    else
      phone_office
    end
  end

  def name
    "#{first_name}#{" " unless first_name.blank?}#{last_name}"
  end

end
