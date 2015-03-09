class EventDestroy < Event
  def to_s
    str = ""
    unless notes.blank?
      if notes.is_a?(Array)
        str << I18n.t(notes, :default => notes).join(" ")
      else
        str << I18n.t(notes, :default => notes)
      end
    end
    str
  end
end
