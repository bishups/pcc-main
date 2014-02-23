class Program < ActiveRecord::Base
  validates :slot, :presence => true
  validates :start_date, :presence => true
  #validates :end_date, :presence => true
  validates :center_id, :presence => true
  validates :proposer_id, :presence => true

  attr_accessible :name
  attr_accessible :program_type_id
  attr_accessible :start_date
  attr_accessible :center_id
  attr_accessible :slot

  before_create :assign_dates!

  private

  def assign_dates!
    # TODO: Assign end date based on ProgramType
  end
end
