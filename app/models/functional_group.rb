# == Schema Information
#
# Table name: functional_groups
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FunctionalGroup < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :permissions

  validates :name,:permissions, :presence => true

  attr_accessible :name, :permission_ids


  rails_admin do
    list do
      field :name
      field :permissions
    end
    edit do
      field :name
      field :permissions
    end
  end

end
