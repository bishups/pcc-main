=begin
class ProgramTeacherSchedule < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :program_id
  attr_accessible :teacher_schedule_id
  #attr_accessible :user_id

  belongs_to :user
  belongs_to :program
  belongs_to :teacher_schedule

  validates :program_id, :presence => true
  validates :teacher_schedule_id, :presence => true
  #validates :user_id, :presence => true
  validates :created_by_user_id, :presence => true
  validates_uniqueness_of :program_id, :scope => [:teacher_schedule_id]
  validates :start_date, :end_date, :overlap => [:teacher_schedule_id, :slot]

  before_create :copy_program_attributes!

  private

  def copy_program_attributes!
    self.user_id = self.teacher_schedule.user_id
    self.start_date = self.program.start_date
    self.end_date = self.program.end_date
    self.slot = self.program.slot
  end
end
=end

class ProgramTeacherSchedule < ActiveRecord::Base

  #composed_of :program, mapping: %w(program_id id)
  #composed_of :teacher_schedule, mapping: [ %w(teacher_id teacher_id), %w(schedule_id id), %w(reserving_user_id reserving_user_id) ]

  attr_accessor :teacher_id, :teacher, :reserving_user_id, :program, :program_id, :teacher_schedule, :teacher_schedule_id

  # attr_accessible :program, :program_id, :teacher_id, :reserving_user_id
  # validates :program_id, :teacher_id, :reserving_user_id, :presence => true



  STATE_PROPOSED  = :proposed
  STATE_APPROVED  = :approved
  STATE_REJECTED  = :rejected
  STATE_POSSIBLE  = :possible
  STATE_PENDING_FINANCE_APPROVAL = :pending_finance_approval
  STATE_INSUFFICIENT_INFO = :insufficient_info
  STATE_PUBLISHED = :published

  PROCESSABLE_EVENTS = [
      :approve, :reject, :publish, :possible, :insufficient_info, :finance_approval
  ]

  state_machine :state, :initial => STATE_PROPOSED do
    event :approve do
      transition [STATE_PROPOSED, STATE_REJECTED] => STATE_APPROVED
    end

    after_transition any => STATE_APPROVED do |venue, transition|
      # TODO: check if paid venue or not
      if venue.paid?
        venue.finance_approval()
      else
        venue.possible()
      end
    end

    event :finance_approval do
      transition [STATE_APPROVED, STATE_INSUFFICIENT_INFO] => STATE_PENDING_FINANCE_APPROVAL
    end

    event :possible do
      transition [STATE_APPROVED, STATE_PENDING_FINANCE_APPROVAL] => STATE_POSSIBLE
    end

    event :reject do
      transition [STATE_PROPOSED, STATE_POSSIBLE] => STATE_REJECTED
    end

    event :publish do
      transition [STATE_POSSIBLE] => STATE_PUBLISHED
    end

    event :insufficient_info do
      transition STATE_PENDING_FINANCE_APPROVAL => STATE_INSUFFICIENT_INFO
    end

  end


end

