class RenameKitIdStringToKitNameString < ActiveRecord::Migration
  def up
    rename_column :kits , :kid_id_string , :kit_name_string
  end

  def down
  end
end
