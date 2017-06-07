class AddDeliveryFieldsToInvoices < ActiveRecord::Migration

  def change
    add_column :invoices, :delivery_date,          :date
    add_column :invoices, :delivery_location_id,   :string
    add_column :invoices, :delivery_location_type, :string
    add_column :invoices, :delivery_address,       :string
    add_column :invoices, :delivery_city,          :string
    add_column :invoices, :delivery_postalcode,    :string
    add_column :invoices, :delivery_province,      :string
    add_column :invoices, :delivery_country,       :string
  end

end
