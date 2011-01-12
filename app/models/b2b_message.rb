require "active_resource"

class B2bMessage < ActiveResource::Base

  unloadable

  def <=>(oth)
    self.created_at <=> oth.created_at
  end

  def discarded?
    return false if self.retries.nil?
    self.retries >= 5
  end

end

