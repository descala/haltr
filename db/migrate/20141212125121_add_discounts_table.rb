class AddDiscountsTable < ActiveRecord::Migration

  def up
    create_table :discounts do |t|
      t.integer :invoice_line_id
      t.float   :percent
      t.string  :text
    end
    add_index(:discounts, :invoice_line_id)
    Invoice.where('discount_percent > 0').each do |invoice|
      invoice.invoice_lines.each do |line|
        Discount.create!(
          percent: invoice.discount_percent,
          text: invoice.discount_text,
          invoice_line_id: line.id
        )
      end
    end
    remove_column :invoices, :discount_percent
    remove_column :invoices, :discount_text
  end

  def down
    add_column :invoices, :discount_percent, :integer, :default => 0
    add_column :invoices, :discount_text
    drop_table :discounts
  end

end
