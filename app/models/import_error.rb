class ImportError < ActiveRecord::Base

  belongs_to :project


  def original=(s)
    write_attribute(:original, Haltr::Utils.compress(s))
  end

  def original
    Haltr::Utils.decompress(read_attribute(:original))
  end

end
