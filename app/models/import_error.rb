class ImportError < ActiveRecord::Base

  unloadable
  belongs_to :project

end
