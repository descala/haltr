class RefactorEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :type, :string, :default => 'Event'
    add_column :events, :file, :text, :limit => 16777215
    add_column :events, :content_type, :string

    execute 'UPDATE events SET type="ReceivedInvoiceEvent" WHERE name="email";'
    execute 'UPDATE events SET type="EventWithUrl" WHERE md5 is not NULL;'
    execute 'UPDATE events SET type="EventWithMail" WHERE name LIKE "%paid_notification" and md5 is NULL;'

    # info is now a serialized Hash
    execute 'UPDATE events SET info=concat("---\n' +
      ':notes: ", COALESCE(info,""), "\n' +
      ':md5: ", COALESCE(md5,""), "\n' +
      ':final_md5: ", COALESCE(final_md5,""), "\n' +
      '");'

    remove_column :events, :md5
    remove_column :events, :final_md5
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
