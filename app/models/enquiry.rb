class Enquiry < ActiveRecord::Base
  attr_accessible :description, :email, :mobile, :name, :phone, :topic

  validates :name, :presence => true
  validates :email, :presence => true
  validates :topic, :presence => true
  validates :description, :presence => true

  state_machine :state, :initial => :new do
    event :respond do
      transition :new => :processing
    end

    event :close do
      transition any => :closed
    end
  end

end
