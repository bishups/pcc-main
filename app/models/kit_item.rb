class KitItem < ActiveRecord::Base
  attr_accessible :comments, :count, :description, :name, :condition
  belongs_to :kit
  attr_accessible :kit_id, :kit
  belongs_to :kit_item_name
  attr_accessible :kit_item_name_id, :kit_item_name
  validates :kit, :kit_item_name, :description, :condition, :presence => true
  validates :count, :numericality => {:only_integer => true }

  rails_admin do
    navigation_label 'Kit Management'
    weight 1
    list do
      field :kit
      field :kit_item_name
      field :description
      field :condition
      field :count
    end
    edit do
      field :kit  do
        #inline_add false
        inline_edit false
      end
      field :kit_item_name  do
        inline_add false
        inline_edit false
      end
      field :description
      field :condition
      field :count
      field :comments
    end

  end
end
