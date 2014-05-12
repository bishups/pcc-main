# == Schema Information
#
# Table name: zones
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Zone < ActiveRecord::Base
  has_many :sectors
  has_many :centers, :through => :sectors
  has_many :access_privileges, :as => :resource, :inverse_of => :resource
#  acts_as_paranoid

  validates :name, :presence => true

  attr_accessible :name, :sector_ids, :sectors

  def self.by_centers(centers)
    joins(:sectors).joins(:centers).where(:centers=>{:id=>centers}).uniq
  end

  def self.by_sectors(sectors)
    joins(:sectors).where(:sectors=>{:id=>sectors}).uniq
  end


  # usage -> ::Zone::all_sectors_in_one_zone? [sector1, sector2, sector3]
  def self.all_sectors_in_one_zone?(sectors)
    if !sectors.empty?
      zone_id = sectors[0].zone_id
      sectors.each {|c| return false if zone_id != c.zone_id }
    end
    true
  end

  # usage -> ::Sector::all_centers_in_one_zone?? [center1, center2, center3]
  def self.all_centers_in_one_zone?(centers)
    if !centers.empty?
      zone_id = centers[0].sector.zone_id
      centers.each {|c| return false if zone_id != c.sector.zone_id }
    end
    true
  end

  rails_admin do
    navigation_label 'Geo-graphical informations'
      weight 0
    visible do
      bindings[:controller].current_user.is?(:zonal_coordinator)
    end
    list do
      field :name
      field :sectors
    end
    edit do
      field :name do
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
      field :sectors   do
         inline_add false
         associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
         associated_collection_scope do
           # bindings[:object] & bindings[:controller] are available, but not in scope's block!
           accessible_sectors = bindings[:controller].current_user.accessible_sectors(:sector_coordinator)
           Proc.new { |scope|
             # scoping all Players currently, let's limit them to the team's league
             # Be sure to limit if there are a lot of Players and order them by position
             # scope = scope.where(:id => accessible_centers )
             scope = scope.where(:id => accessible_sectors )
           }
         end
      end
    end
  end

end
