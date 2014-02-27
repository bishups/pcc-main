class AddKitIdStringToKit < ActiveRecord::Migration
  def change
    add_column :kits, :kid_id_string , :string
  end
end
