class CreateBoards < ActiveRecord::Migration[5.1]
  def change
    create_table :boards do |t|
      t.integer :turn
      t.text :row1
      t.text :row2
      t.text :row3
      t.text :row4
      t.text :row5
      t.text :row6
      t.text :row7
      t.text :row8

      t.timestamps
    end
  end
end
