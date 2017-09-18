class Terms



  KEYS = %w(0 15 30 60 90 120 0m-1 1m-1 1m1 2m1 1m15 1m20 1m10)

  attr_reader :description, :due_date
  
  def initialize(code, date=nil)
    date = date.nil? ? Date.today : date
    if code.to_i.to_s == code.to_s or code.nil? or code.blank?
      # It's a number
      if code.to_i == 0
        @due_date = date
      else
        @due_date = date + code.to_i.day
      end
    else
      # It's an string
      if code =~ /([0-9]+)+m(-?[0-9]+)/
        months_to_add = $1.to_i
        day = $2.to_i
        date_with_months = date + months_to_add.months
        @due_date = Date.new(date_with_months.year,date_with_months.month,day)
      end
    end
    @description = I18n.t(code) if code and !code.blank?
  end

  def self.for_select
    [['---','---']] + KEYS.collect {|k| [I18n.t(k), k] } + [[I18n.t("custom"), "custom"]]
  end
    
end

