# == Schema Information
# Schema version: 20091016144057
#
# Table name: people
#
#  id                :integer(4)      not null, primary key
#  client_id         :integer(4)
#  first_name        :string(255)
#  last_name         :string(255)
#  email             :string(255)
#  phone_office      :string(255)
#  phone_mobile      :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  invoice_recipient :boolean(1)
#  report_recipient  :boolean(1)
#

class Person < ActiveRecord::Base
  belongs_to :client
 
  validates_presence_of :client, :first_name, :last_name, :email
  validates_uniqueness_of :email, :scope => :client_id

  def to_label
    "#{first_name} #{last_name}"
  end
  
end
