class CreateMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :line_user_id

      t.timestamps
    end
    add_index :members, :line_user_id
  end
end
