# == Schema Information
#
# Table name: program_donations
#
#  id              :integer          not null, primary key
#  program_type_id :integer
#  donation        :integer
#  name            :string(255)
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sync_ts         :string(255)
#  sync_id         :string(255)
#

class ProgramDonation < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :program_type
  attr_accessible :donation, :name, :program_type, :program_type_id
  validates :name, :program_type, :presence => true
  validates_uniqueness_of :name, :scope => :deleted_at
  validates :donation, :presence => true,  :length => {:within => 1..6}, :numericality => {:only_integer => true }

  has_and_belongs_to_many :centers
  attr_accessible :centers, :center_ids

  rails_admin do
    navigation_label 'Program'
    weight 0
    visible do
      bindings[:controller].current_user.is?(:super_admin)
    end
    list do
      field :name
      field :program_type
      field :donation
    end
    edit do
      field :name
      field :program_type do
        inline_add false
        inline_edit false
      end
      field :donation do
        help "Required. In Rupees."
      end
    end
  end
end
