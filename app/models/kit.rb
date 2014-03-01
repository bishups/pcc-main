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
  has_many :kit_item_mappings
  has_many :kit_items, :through => :kit_item_mappings

  attr_accessible :condition_comments, :general_comments, :kit_item_mappings
  accepts_nested_attributes_for :kit_item_mappings

  has_paper_trail

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

#canBeBlocked
end
