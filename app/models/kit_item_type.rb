class KitItemType < ActiveRecord::Base
  attr_accessible :name, :description

  validates :name, :presence => true
  rails_admin do
    navigation_label 'Kit Management'
    weight 2
    list do
      field :name
      field :description
    end
    edit do
      field :name
      field :description
    end
  end
end