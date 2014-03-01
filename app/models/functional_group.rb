class FunctionalGroup < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :permissions

  validates :name, :presence => true

  attr_accessible :name, :permission_ids

end
