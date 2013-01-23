class Person < ActiveRecord::Base

  unloadable

  belongs_to :client

  validates_presence_of :client, :first_name, :last_name, :email
  validates_uniqueness_of :email, :scope => :client_id
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true

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
