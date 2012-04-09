class RenamePersonIdToPosterIdForPost < ActiveRecord::Migration
  def change
    rename_column :posts, :person_id, :poster_id
  end
end
