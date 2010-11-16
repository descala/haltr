class Company < ActiveRecord::Base

  unloadable

  belongs_to :project
  validates_presence_of :name, :project_id
  validates_length_of :taxid, :maximum => 9
  validates_length_of :bank_account, :maximum => 24

  def <=>(oth)
    self.name <=> oth.name
  end

end
