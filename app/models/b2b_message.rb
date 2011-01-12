require "active_resource"

class B2bMessage < ActiveResource::Base

  unloadable

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

  def discarded?
    self.retries >= 5
  end

end

