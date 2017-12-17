class AddValidListToBoards < ActiveRecord::Migration[5.1]
  def change
    add_column :boards, :validList, :text
  end
end
