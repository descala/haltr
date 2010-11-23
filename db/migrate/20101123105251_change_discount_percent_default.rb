class ChangeDiscountPercentDefault < ActiveRecord::Migration

  def self.up
    change_column_default :invoices, :discount_percent, 0
    Invoice.all.each { |i|
      i.discount_percent ||= 0
      i.save
    }
  end

  def self.down
    change_column_default :invoices, :discount_percent, nil
  end

end
