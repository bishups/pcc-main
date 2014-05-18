class RemoveCenterIdFromKit < ActiveRecord::Migration
  def change
    remove_column :kits, :center_id
  end
end
