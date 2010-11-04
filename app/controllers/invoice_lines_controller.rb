class InvoiceLinesController < ApplicationController
  
  unloadable

  COLS = ['quantity','description','price']
  
  active_scaffold do |config|
    config.list.columns = ['invoice','quantity','description','price']
    config.create.columns = COLS
    config.update.columns = COLS
    config.show.columns = COLS
#    config.columns[:description].options[:rows]=2
  end

end
