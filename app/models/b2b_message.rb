require "activeresource"

class B2bMessage < ActiveResource::Base

  unloadable

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

end

