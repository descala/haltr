module Utils
  class << self
    
    def replace_dates!(text,date)
      return nil if text.nil?
      months = I18n.backend.translate("#{I18n.locale}.date.month_names", "")
      months.each do |m|
        text.gsub!(/#{m}/i, months[date.month]) unless m.nil? or months[date.month].nil?
      end
      text.gsub!(/20[0-5][0-9]/, date.year.to_s)
      text
    end
    
  end
end

class String
  def to_ascii
    Redmine::CodesetUtil.from_utf8(self,'ASCII')
  end
end
