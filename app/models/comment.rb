class Comment < ActiveRecord::Base
  attr_accessible :action, :model, :text

  validates :action, :model, :text, :presence => true

  rails_admin do
    navigation_label 'Admin'
    weight 1
    list do
      field :model
      field :action
      field :text
    end
    edit do
      field :model
      field :action
      field :text
    end
  end
end
