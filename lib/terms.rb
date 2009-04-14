# -*- coding: utf-8 -*-
class Terms

  NOW = "al comptat"
  DAYS = "%d dies"
  DAYNM = "dia %d mes següent"
  
  attr_reader :description, :due_date
  
  def initialize(code, date=Date.today)
    if code.to_i.to_s == code.to_s or code.nil?
      # It's a number
      if code.to_i == 0
        @description = NOW
        @due_date = date
      else
        @description = sprintf(DAYS,code.to_i)
        @due_date = date + code.to_i.day
      end
    else
      # It's an string
      if code[/1m[0-9]+/]
        day = code[2..3].to_i
        @description = sprintf(DAYNM,day)
        @due_date = Date.new(date.next_month.year,date.next_month.month,day)
      end
    end
  end
    
end
