class Pincode < ActiveRecord::Base
  belongs_to :center
  attr_accessible :location_name, :pincode, :center, :center_id
  validates :location_name, :pincode, :presence => true


  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 3
    object_label_method do
      :location_name
    end
    list do
      field :location_name
      field :pincode
      field :center
    end
    edit do
      field :location_name
      field :pincode
      field :center do
        inline_edit do
          false
        end
        inline_add do
          false
        end
      end
    end
  end

end
