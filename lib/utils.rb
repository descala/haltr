# -*- coding: utf-8 -*-
module Utils
  class << self
    def remove_non_ascii(t)
      t.gsub!(/à|á|ä/,'a')
      t.gsub!(/è|é|ë/,'e')
      t.gsub!(/í|ì|ï/,'i')
      t.gsub!(/ò|ó|ö/,'o')
      t.gsub!(/ú|ù|ü/,'u')
      t.gsub!(/ñ/,'n') 
      t.gsub!(/ç/,'c') 
      t.gsub!(/À|Á|Ä/,'A')
      t.gsub!(/È|É|Ë/,'E')
      t.gsub!(/Í|Ì|Ï/,'I')
      t.gsub!(/Ò|Ó|Ö/,'O')
      t.gsub!(/Ú|Ù|Ü/,'U')
      t.gsub!(/Ñ/,'N') 
      t.gsub!(/Ç/,'C') 
      return t
    end
    
    def replace_dates!(text,date)
      return nil if text.nil?
      months = I18n.backend.translate("#{I18n.locale}.date.month_names", "")
      months.each do |m|
        text.gsub!(/#{m}/i, months[date.month]) unless m.nil?
      end
      text.gsub! /20[0-5][0-9]/, date.year.to_s
      text
    end
    
  end
end

class String
  def to_ascii
    Utils::remove_non_ascii(self)
  end
end
