# == Schema Information
#
# Table name: kits
#
#  id                     :integer          not null, primary key
#  state                  :string(255)
#  max_participant_number :integer
#  filling_person_id      :integer
#  center_id              :integer
#  guardian_id            :integer
#  issued_to_person_id    :integer
#  blocked_by_person_id   :integer
#  assigned_to_program_id :integer
#  condition              :string(255)
#  condition_comments     :text
#  general_comments       :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Kit < ActiveRecord::Base
  attr_accessible :condition,:condition_comments,
                  :general_comments, :kit_name_string,
                  :center_id,:state,:max_participant_number

  has_many :kit_item_mappings
  has_many :kit_schedules
  has_many :kit_items, :through => :kit_item_mappings
  belongs_to :center
  has_paper_trail
  
  before_create :generateKitNameString
  before_update :generateKitNameString
  
  state_machine :state, :initial => :new do
    event :approve do
      transition :new => :available
    end


    #will be manual event
    event :block do
      #check availability for given period
      transition :available => :blocked, :if => lambda { |kit| !vehicle.passed_inspection? }
      # DB - period kit_id - blocked
    end

    #will be automatic event when proram is announced!
    event :assign do
      transition :blocked => :assigned, :if => lambda { |kit| !vehicle.passed_inspection? }
      # DB - period kit_id - assigned
    end

  end
  
  private
  def generateKitNameString
    center = Center.find(self.center_id )
    name = center.name+"_"+self.max_participant_number.to_s+"_"+self.id.to_s
    self.kit_name_string = name
  end

#canBeBlocked
end
