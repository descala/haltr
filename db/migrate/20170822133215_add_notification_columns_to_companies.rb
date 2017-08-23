class AddNotificationColumnsToCompanies < ActiveRecord::Migration

  def up
    #add_column :companies, :issued_invoice_notifications,    :string
    #add_column :companies, :received_invoice_notifications,  :string
    #add_column :companies, :received_order_notifications,    :string
    #add_column :companies, :sii_imported_notifications,      :string
    #add_column :companies, :sii_sent_notifications,          :string
    #add_column :companies, :sii_state_changes_notifications, :string

    Company.all.each do |company|

      next if company.project.nil?

      if company.bcc_me?
        company.issued_invoice_notifications = company.email
      end
      if company.invoice_notifications?
        company.received_invoice_notifications = company.project.notified_users.
          select {|user| user.allowed_to?(:general_use, company.project)}.
          collect(&:mail).join(',')
      end
      if company.order_notifications?
        company.received_order_notifications = company.project.notified_users.
          select {|user| user.allowed_to?(:use_orders, company.project)}.
          collect(&:mail).join(',')
      end
      if company.project.enabled_modules.any? {|m| m.name == 'sii'}
        company.sii_imported_notifications      = company.email
        company.sii_sent_notifications          = company.email
        company.sii_state_changes_notifications = company.email
      end
      company.save(validate: false)
    end
    remove_column :companies, :bcc_me
    remove_column :companies, :invoice_notifications
    remove_column :companies, :order_notifications
  end

  def down
    remove_column :companies, :issued_invoice_notifications
    remove_column :companies, :received_invoice_notifications
    remove_column :companies, :received_order_notifications
    remove_column :companies, :sii_imported_notifications
    remove_column :companies, :sii_sent_notifications
    remove_column :companies, :sii_state_changes_notifications

    add_column :companies, :bcc_me,                :boolean, default: true
    add_column :companies, :invoice_notifications, :boolean, default: false
    add_column :companies, :order_notifications,   :boolean, default: false
  end

end
