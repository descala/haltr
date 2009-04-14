class PeopleController < ApplicationController

  COLS = ["client","first_name","last_name","email","phone_office","phone_mobile","invoice_recipient","report_recipient"]
  
  active_scaffold :person do |config|
    config.columns[:client].form_ui = :select
    config.list.columns = ["client","first_name","last_name","email","invoice_recipient","report_recipient"]
    config.create.columns = COLS
    config.update.columns = COLS
    config.show.columns = COLS
  end
end
