# == Schema Information
#
# Table name: centers
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  sector_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Center < ActiveRecord::Base

  acts_as_paranoid

  belongs_to :sector
  has_many :pincodes
  has_one :zone, :through => :sector
  has_many :access_privileges, :as => :resource, :inverse_of => :resource
  has_many :users, :through => :access_privileges
  has_and_belongs_to_many :teachers
  has_and_belongs_to_many :kits
  has_and_belongs_to_many :venues
  has_and_belongs_to_many :teacher_schedules, :join_table => "centers_teacher_schedules"
  attr_accessible :name, :sector_id, :sector, :pincodes, :pincode_ids, :zone, :zone_id, :teacher_schedules, :teacher_schedule_ids

  has_and_belongs_to_many :program_donations
  attr_accessible :program_donations, :program_donation_ids

  validates :name, :sector, :presence => true

  rails_admin do
    navigation_label 'Geo-graphical informations'
    weight 2
    visible do
      bindings[:controller].current_user.is?(:sector_coordinator)
    end
    list do
      field :name
      field :sector
      field :zone
      field :pincodes
      field :program_donations
    end
    edit do
      field :name
      field :sector do
        inline_edit false
        inline_add false
      end
      field :pincodes do
        help " Only Pincodes which are not already used by any Center are listed above. If your Pincode is missing, please contact Help desk."
        inline_add do
          false
        end
        #associated_collection_cache_all true # REQUIRED if you want to SORT the list as below
        associated_collection_scope do
          # bindings[:object] & bindings[:controller] are available, but not in scope's block!
          Proc.new { |scope|
            # scoping all Players currently, let's limit them to the team's league
            # Be sure to limit if there are a lot of Players and order them by position
            # scope = scope.where(:id => accessible_centers )
            scope = Pincode.unused
          }
        end
      end
      field :program_donations do
        inline_add false
      end
    end
    update do
      configure :name  do
        read_only do
          not bindings[:controller].current_user.is?(:super_admin)
        end
      end
    end

  end

end
