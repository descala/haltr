class EventError < Event
  def to_s
    "#{l(name)} #{notes}"
  end
end
