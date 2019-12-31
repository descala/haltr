module Utils
  class << self

    def replace_dates!(text,date)
      return nil if text.nil?
      locale = I18n.locale.to_s
      raise "blank locale" if locale.blank?
      months = I18n.t("date.month_names", locale: locale)
      months.each do |m|
        unless m.nil? or months[date.month].nil?
          text.gsub!(/\b#{m}\b/i, months[date.month])
        end
      end
      text.gsub!(/\b20[0-5][0-9]\b/, " #{date.year.to_s}")
      text
    end

  end
end

class String
  def to_ascii
    Redmine::CodesetUtil.from_utf8(self,'ASCII')
  end
end
