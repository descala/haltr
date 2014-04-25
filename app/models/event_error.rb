class EventError < Event
  def to_s
    str = l(name)
    str += ": #{notes}" unless notes.blank?
    str
  end
end
