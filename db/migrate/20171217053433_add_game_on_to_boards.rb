class AddGameOnToBoards < ActiveRecord::Migration[5.1]
  def change
    add_column :boards, :gameOn, :text
  end
end
