class AddFieldNotesFormInPeople < ActiveRecord::Migration

  def change
    add_column :people, :info, :string

  end

end
