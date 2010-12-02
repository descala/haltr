class Terms

  unloadable

  KEYS = %w(0 30 60 90 120 1m1 2m1 1m15 1m20)

  NOW = "al comptat"
  DAYS = "%d dies"
  DAYNM = "dia %d mes següent"
  
  attr_reader :description, :due_date
  
  def initialize(code, date=Date.today)
    if code.to_i.to_s == code.to_s or code.nil? or code.blank?
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
      if code=~/([0-9]+)+m([0-9]+)/
        months_to_add = $1.to_i
        day = $2.to_i
        date_with_months = date + months_to_add.months
        if months_to_add == 1
          @description = sprintf(DAYNM,day)
        else
          months = I18n.backend.translate("#{I18n.locale}.date.month_names", "")
          @description = "#{day} de #{months[date_with_months.month]}"
        end
        @due_date = Date.new(date_with_months.year,date_with_months.month,day)
      end
    end
  end

  def self.for_select
    KEYS.collect {|k| [I18n.t(k), k] } + [[I18n.t("custom"), "custom"]]
  end
    
end

