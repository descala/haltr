class Payment < ActiveRecord::Base

  unloadable

  belongs_to :invoice
  belongs_to :project

end
