class AddLanguageToExternalCompanies < ActiveRecord::Migration

  def up
    add_column :external_companies, :language, :string, :default => I18n.default_locale.to_s
  end

  def down
    remove_column :external_companies, :language
  end

end
