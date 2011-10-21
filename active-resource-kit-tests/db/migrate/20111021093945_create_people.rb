class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :first
      t.string :last

      t.timestamps
    end
  end
end
