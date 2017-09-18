class ImportError < ActiveRecord::Base

  belongs_to :project

  attr_protected :created_at, :updated_at

  def original=(s)
    write_attribute(:original, Haltr::Utils.compress(s))
  end

  def original
    Haltr::Utils.decompress(read_attribute(:original))
  end

end
