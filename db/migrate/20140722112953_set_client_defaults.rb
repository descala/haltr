class SetClientDefaults < ActiveRecord::Migration

  def up
    execute "update clients set payment_method=1 where payment_method is null;"
    execute "update clients set terms=0 where terms is null;"
  end

  def down
  end

end
