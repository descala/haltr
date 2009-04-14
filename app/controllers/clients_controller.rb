class ClientsController < ApplicationController

  COLS = ['name','address1','address2','city','province','postalcode','country','taxcode','bank_account']
  
  active_scaffold do |config|
    config.list.columns = ['name','taxcode','invoices','people']
    config.create.columns = COLS
    config.update.columns = COLS
    config.show.columns = COLS
  end

end
