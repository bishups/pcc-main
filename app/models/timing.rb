# == Schema Information
#
# Table name: timings
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  start_time :time
#  end_time   :time
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  sync_id    :integer
#

class Timing < ActiveRecord::Base

  acts_as_paranoid

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
  validates_uniqueness_of :name, :scope => :deleted_at

  before_validation :remove_date
  validate :overlap

  # given a program, returns a relation with other overlapping program(s)
  scope :overlapping, lambda { |timing| Timing.where('((start_time > ? AND start_time < ?) OR (end_time > ? AND end_time < ?) OR  (start_time < ? AND end_time > ?)) AND (id != ? OR ? IS NULL) ',
                                                     timing.start_time, timing.end_time, timing.start_time, timing.end_time, timing.start_time, timing.end_time, timing.id, timing.id) }

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

  def overlap
    if Timing.overlapping(self).count > 0
      self.errors[:base] << "Timing overlaps with other timings. Please adjust the specified start (or end) time."
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
