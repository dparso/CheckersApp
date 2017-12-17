class RemoveValidFromBoards < ActiveRecord::Migration[5.1]
  def change
    remove_column :boards, :valid, :text
  end
end
