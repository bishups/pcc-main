class Pincode < ActiveRecord::Base
  belongs_to :center
  attr_accessible :location_name, :pincode, :center, :center_id
#  validates :center, :presence => true
  validates :location_name, :presence => true, :uniqueness => true
  validates :pincode,  :presence => true, :length => { is: 6}, :numericality => {:only_integer => true }

  validates_uniqueness_of :pincode, :scope => :deleted_at

  scope :unused, where({:center_id => nil})

  acts_as_paranoid

  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 3
    visible do
      bindings[:controller].current_user.is?(:sector_coordinator)
    end
    object_label_method do
      :pincode
    end
    list do
      field :location_name
      field :pincode
      field :center
    end
    edit do
      field :location_name
      field :pincode do
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
    end
  end

end
