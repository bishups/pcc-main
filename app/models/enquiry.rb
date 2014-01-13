# == Schema Information
#
# Table name: enquiries
#
#  id          :integer          not null, primary key
#  topic       :string(255)
#  name        :string(255)
#  email       :string(255)
#  phone       :string(255)
#  mobile      :string(255)
#  description :text
#  state       :string(255)
#  external_id :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Enquiry < ActiveRecord::Base
  attr_accessible :description, :email, :mobile, :name, :phone, :topic

  validates :name, :presence => true
  validates :email, :presence => true
  validates :topic, :presence => true
  validates :description, :presence => true

  state_machine :state, :initial => :new do
    event :start_process do
      transition :new => :processing
    end

    event :pending do
      transition :processing => :pending
    end

    event :duplicate do
      transition any => :duplicate
    end

    event :invalid do
      transition any => :invalid
    end

    event :close do
      transition any => :closed
    end
  end

  def add_comment(comment)
  end

end
