class CreateProviders < ActiveRecord::Migration

  def change
    create_table :providers do |t|
      t.references :company, index: true, foreign_key: true
      t.references :company_provider, index: true

      t.timestamps null: false
    end

    add_index :providers, [:company_id, :company_provider_id], unique: true
  end

end
