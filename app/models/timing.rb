class Timing < ActiveRecord::Base
  attr_accessible :end_time, :name, :start_time
  belongs_to :timing, :polymorphic => true
  has_and_belongs_to_many :program_types
  attr_accessible :program_type_ids, :program_types

  has_and_belongs_to_many :programs, :join_table => :programs_timings
  attr_accessible :program_ids, :programs

  has_many :teacher_schedules
  has_many :teachers, through: :teacher_schedules
  validates :name, :start_time, :end_time, :presence => true
  validate :start_end_time?

  before_validation :remove_date

  def remove_date
    # this is hack to get iron out the dates being store to standard date
    self.start_time = self.start_time.change(:month => 1, :day => 1, :year => 2000)
    self.end_time = self.end_time.change(:month => 1, :day => 1, :year => 2000)
  end

  def start_end_time?
    if self.end_time <= self.start_time
      self.errors[:end_time] << " cannot be before the start time."
    end
  end

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
