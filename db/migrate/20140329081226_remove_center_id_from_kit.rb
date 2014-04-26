class RemoveCenterIdFromKit < ActiveRecord::Migration
  def change
    remove_column :kits, :center_id, :integer
  end
end