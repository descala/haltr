class Person < ActiveRecord::Base

  include Redmine::SafeAttributes
  safe_attributes(*(column_names - [
    'id','created_at','updated_at'
  ] + ['client']))

  belongs_to :client

  validates_presence_of :client, :first_name, :last_name
  validates_uniqueness_of :email, :scope => :client_id, :allow_blank => true
  validates_format_of :email,
    :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+(,[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+)*\z/,
    :allow_nil => true,
    :allow_blank => true
  validates :first_name, :last_name, :email, :phone_office, :phone_mobile,
    :info, length: { maximum: 255 }


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
