class KitItem < ActiveRecord::Base
  attr_accessible :comments, :count, :description, :name, :condition
  belongs_to :kit
  attr_accessible :kit_id, :kit
  belongs_to :kit_item_type
  attr_accessible :kit_item_type_id, :kit_item_type
  validates :kit, :kit_item_type, :condition, :presence => true
  validates :count, :length => {:within => 1..3}, :numericality => {:only_integer => true }

  rails_admin do
    navigation_label 'Kit Management'
    weight 1
    visible do
      bindings[:controller].current_user.is?(:kit_coordinator)
    end
    list do
      field :kit
      field :kit_item_type
      field :description
      field :condition
      field :count
    end
    edit do
      field :kit  do
        #inline_add false
        inline_edit false
      end
      field :kit_item_type  do
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
