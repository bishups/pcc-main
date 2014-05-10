class Pincode < ActiveRecord::Base
  belongs_to :center
  attr_accessible :location_name, :pincode, :center, :center_id
  validates :center, :presence => true
  validates :location_name, :presence => true, :uniqueness => true
  validates :pincode,  :presence => true, :uniqueness => true, :length => { is: 6}, :numericality => {:only_integer => true }

  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 3
    object_label_method do
      :location_name
    end
    list do
      field :location_name
      field :pincode do
        read_only do
           not bindings[:controller].current_user.is?(:super_admin)
        end
      end
      field :center do
        read_only do
          not ( bindings[:controller].current_user.is?(:sector_coordinator) or bindings[:controller].current_user.is?(:super_admin) )
        end
      end
    end
    edit do
      field :location_name
      field :pincode
      #field :center do
      #  inline_edit false
      #  inline_add false
      #end
    end
  end

end
