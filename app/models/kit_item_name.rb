class KitItemName < ActiveRecord::Base
  attr_accessible :name

  validates :name, :presence => true
  rails_admin do
    navigation_label 'Kit Management'
    weight 2
    list do
      field :name
    end
    edit do
      field :name

    end
  end
end