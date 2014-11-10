# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  model      :string(255)
#  action     :string(255)
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  active     :boolean          default(TRUE)
#

class Comment < ActiveRecord::Base

  acts_as_paranoid

  attr_accessible :action, :model, :text, :active

  validates :action, :model, :text, :presence => true

#  validate :can_update?, :before => :update
  before_destroy :can_delete?

#  def can_update?
#    if self.model_changed? || self.action_changed? || self.text_changed?
#      self.errors[:base] = " -- comment cannot be edited. It can only be marked inactive."
#      return false
#    end
#  end

#  def can_delete?
#    self.errors[:base] << " -- comment cannot be deleted. It can only be marked inactive."
#    return false
#  end

  rails_admin do
    navigation_label 'Admin'
    weight 1
    list do
      field :model
      field :action
      field :text
#      field :active
    end
    edit do
      field :model
      field :action
      field :text
#      field :active do
#        help 'Toggle to activate/deactivate. De-activating a comment will remove it from the drop-down list.'
#      end
    end
  end
end
