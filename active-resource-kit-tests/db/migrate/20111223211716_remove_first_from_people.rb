class RemoveFirstFromPeople < ActiveRecord::Migration
  def up
    remove_column :people, :first
    remove_column :people, :last
  end

  def down
    add_column :people, :first, :string
    add_column :people, :last, :string
  end
end
