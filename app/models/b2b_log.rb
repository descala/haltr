require "active_resource"

class B2bLog < ActiveResource::Base



  def <=>(oth)
    self.created_at <=> oth.created_at
  end

end

