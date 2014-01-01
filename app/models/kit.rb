class Kit < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :kit_item_mappings
  has_many :kit_items, :through => :kit_item_mappings

  state_machine :state, :initial => :new do
  	event :approve do
  		transition :new => :available
  	end


  	#will be manual event
  	event :block do
  		#check availability for given period
  		transition :available => :blocked, :if => lambda {|kit| !vehicle.passed_inspection?}
  		# DB - period kit_id - blocked
  	end

  	#will be automatic event when proram is announced!
  	event :assign do
   		transition :blocked => :assigned, :if => lambda {|kit| !vehicle.passed_inspection?}
  		# DB - period kit_id - assigned
  	end

  end

#canBeBlocked
end
