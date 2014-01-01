class KitItem < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :kit_item_mappings
  has_many :kits, :through => :kit_item_mappings
end
