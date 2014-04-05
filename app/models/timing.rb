class Timing < ActiveRecord::Base
  attr_accessible :end_time, :name, :start_time
  belongs_to :timing, :polymorphic => true
  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types

  has_and_belongs_to_many :programs
  attr_accessible :program_ids, :programs

  validates :name, :start_time, :end_time, :presence => true

  rails_admin do
    navigation_label 'Program'
    label "Timing"
    weight 1
    list do
      field :name
      field :start_time do
        date_format "%H%M%S %p"
      end
      field :end_time do
        date_format "%H%M%S %p"
      end
      field :program_types
    end
    edit do
      field :name
      field :start_time do
        date_format "%H%M%S %p"
      end
      field :end_time do
        date_format "%H%M%S %p"
      end
      field :program_types do
        inline_add false
      end
    end
  end
end
