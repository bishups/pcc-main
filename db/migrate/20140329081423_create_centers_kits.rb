class CreateCentersKits < ActiveRecord::Migration
  def change
    create_table :centers_kits do |t|
      t.belongs_to :center
      t.belongs_to :kit
    end
  end
end
