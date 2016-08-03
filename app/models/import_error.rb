class ImportError < ActiveRecord::Base

  belongs_to :project

  attr_protected :created_at, :updated_at

end
