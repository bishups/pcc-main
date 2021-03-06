# == Schema Information
#
# Table name: sectors
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  zone_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  sync_ts    :string(255)
#  sync_id    :string(255)
#

class Sector < ActiveRecord::Base
  belongs_to :zone, :inverse_of => :sectors
  has_many :centers, :inverse_of => :sector
  has_many :users, :through => :access_privileges

  validates :name,:zone, :presence => true
  validates_uniqueness_of :name, :scope => :deleted_at

  acts_as_paranoid

  has_many :access_privileges, :as => :resource, :inverse_of => :resource

  attr_accessible :name, :zone_id, :center_ids, :centers, :zone

  def self.by_centers(centers)
    joins(:centers).where(:centers=>{:id=>centers}).uniq
  end

  # usage -> ::Sector::all_centers_in_one_sector? [center1, center2, center3]
  def self.all_centers_in_one_sector?(centers)
    if !centers.empty?
      sector_id = centers[0].sector_id
      centers.each {|c| return false if sector_id != c.sector_id }
    end
    true
  end

  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 1
    list do
      field :name
      field :zone
      field :centers
    end
    edit do
      field :name do
        read_only do
          not bindings[:controller].current_user.is?(:zao)
        end
      end
      field :zone  do
        inverse_of  :sectors
        inline_edit do
          false
        end
        inline_add do
          false
        end
        read_only do
          not bindings[:controller].current_user.is?(:zao)
        end
        associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          accessible_zones = (Zone.by_centers(bindings[:controller].current_user.accessible_centers.uniq).uniq  + bindings[:controller].current_user.accessible_zones).uniq
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            # scope = scope.where(:id => accessible_centers )
            scope = scope.where(:id => accessible_zones.map(&:id) )
          }
        end
      end
      field :centers do
        inline_add do
          false
        end
          associated_collection_cache_all true  # REQUIRED if you want to SORT the list as below
          associated_collection_scope do
            # bindings[:object] & bindings[:controller] are available, but not in scope's block!
            accessible_centers = bindings[:controller].current_user.accessible_centers(:zao)
            Proc.new { |scope|
              # scoping all Players currently, let's limit them to the team's league
              # Be sure to limit if there are a lot of Players and order them by position
              # scope = scope.where(:id => accessible_centers )
              scope = scope.where(:id => accessible_centers )
            }
        end
      end
    end
  end

end
