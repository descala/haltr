class EventError < Event
  def to_s
    str = l(name)
    str += ": #{I18n.t(notes, :default => notes)}" unless notes.blank?
    str
  end
end
