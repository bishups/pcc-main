class KitItemMapping < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :kit
  belongs_to :kit_item
end
