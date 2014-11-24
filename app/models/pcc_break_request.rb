class PccBreakRequest < ActiveRecord::Base
  include CommonFunctions

#has_one :ticket, :class_name=>Ticket

  attr_accessor :current_user
  attr_accessible :purpose,:days,:to,:from,:requester_id
  after_create :mark_as_pending!
  belongs_to :last_updated_by_user, :class_name => User
  belongs_to :requester, :class_name => User
  attr_accessor :comment_category
  attr_accessible :comment_category
  attr_accessible :last_update, :last_updated_at

  validates :purpose, :from,:to, :presence => true
  #attr_accessible :attachment, :ticket_name
  #mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.

 # validates :idproofnumber, :numericality => {:only_integer => true }
  has_paper_trail
  has_paper_trail :on => [:update]
  has_paper_trail :only => [:last_updated_by_user,:last_update,:last_updated_at,:comments]
  STATE_NEW= "new"
  STATE_PENDING         = "pending"
  STATE_NEED_CLARIFICATION = "need clarification"
  STATE_APPROVED="approved"
  STATE_REJECTED="rejected"
  STATE_CANCELLED="cancelled"


  FINAL_STATES = [STATE_REJECTED,STATE_CANCELLED]

  EVENT_PROCESSING ="processing"
  EVENT_REQUEST_CLARIFICATION="request clarification"
  EVENT_CLARIFY="clarify"
  EVENT_APPROVE="approve"
  EVENT_REJECT="reject"
  EVENT_CANCEL="cancel"

  PROCESSABLE_EVENTS = [
      EVENT_CANCEL, EVENT_PROCESSING,  EVENT_REQUEST_CLARIFICATION, EVENT_CLARIFY,   EVENT_APPROVE, EVENT_REJECT
  ]
  EVENTS_WITH_COMMENTS = [EVENT_REJECT, EVENT_REQUEST_CLARIFICATION, EVENT_CLARIFY]
  EVENTS_WITH_FEEDBACK=[]
  state_machine :state, :initial => STATE_NEW do

    event EVENT_PROCESSING do
      transition STATE_NEW => STATE_PENDING #, :if => lambda {|t| t.can_create?}
    end

    event EVENT_APPROVE do
      transition STATE_PENDING => STATE_APPROVED ,:if => lambda {|t| t.is_break_approver?}

    end
    before_transition STATE_PENDING => STATE_APPROVED, :do => :is_break_approver?


    event EVENT_REQUEST_CLARIFICATION do
      transition STATE_PENDING => STATE_NEED_CLARIFICATION,:if => lambda {|t| t.is_break_approver?}
    end
    before_transition STATE_PENDING => STATE_NEED_CLARIFICATION, :do => :is_break_approver?

    event EVENT_CLARIFY do
      transition STATE_NEED_CLARIFICATION => STATE_PENDING,:if => lambda {|t| t.is_requester?}
    end
    before_transition STATE_NEED_CLARIFICATION => STATE_PENDING, :do => :is_requester?


     event EVENT_REJECT do
      transition STATE_PENDING => STATE_REJECTED, :if => lambda {|t| t.is_break_approver?}
    end
    before_transition STATE_PENDING => STATE_REJECTED, :do => :is_break_approver?

   event EVENT_CANCEL do
      transition [STATE_PENDING,STATE_APPROVED] => STATE_CANCELLED, :if => lambda {|t| t.is_requester?}
    end
    before_transition [STATE_PENDING,STATE_APPROVED] => STATE_CANCELLED, :do => :is_requester?


  before_transition any => any do |object, transition|
    # Don't return here, else LocalJumpError will occur
    if EVENTS_WITH_COMMENTS.include?(transition.event) && !object.has_comments?
      false
    elsif EVENTS_WITH_FEEDBACK.include?(transition.event) && !object.has_feedback?
      false
    else
      true
    end
  end

  after_transition any => any do |object, transition|
    object.store_last_update!(object.current_user, transition.from, transition.to, transition.event)

    requester=object.requester

    approver=object.get_break_approver



    value = {:send_sms => true, :send_email => true, :additional_text => nil }




    approver.each { |break_approver|
      if (break_approver!= nil)
        UserMailer.email(object, break_approver[0], transition.from, transition.to, transition.event, nil).deliver
        UserMailer.sms(object, break_approver[0], transition.from, transition.to, transition.event, nil).deliver
      end
    }



    UserMailer.email(object, requester, transition.from, transition.to, transition.event, nil).deliver
    UserMailer.sms(object, requester, transition.from, transition.to, transition.event, nil).deliver


  end
  end
  def mark_as_pending!
#   self.send(::Venue::EVENT_PROPOSE) if self.state == ::Venue::STATE_UNKNOWN

# HACK #1 - all this making the centers dirty and reloading the object
# due to open rails bug when trying to save a model with habtm in after_create
# https://rails.lighthouseapp.com/projects/8994/tickets/4553-habtm-association-failure-to-save-in-join-table-with-after_create-callback
# HACK #2 - after HACK #1, some problem with doing a send to state machine
# so setting the state directly and logging in the current context only

      self.state = STATE_PENDING

  end


  def get_break_approver
    pcc_break_approver_roles=[]
    break_approver=[]
    pcc_break_approver_roles=Role.find_all_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_break_approver][:text])
    i=0
    pcc_break_approver_roles.each { |pcc_break_approver_role|
      role_id=pcc_break_approver_role.id
      if(!(Role.find(role_id).users).empty?)
        break_approver[i]=Role.find(role_id).users
        i=i+1
      end
    }
    return break_approver
  end




  def get_updates

    updates = []
    v=self.previous_version

    self.versions.each do |version|
      unless version.reify.nil?
        updates << version.reify.last_update
      end
    end
    return updates
  end

  def get_comments
    comments_made = []

    self.versions.each do |version|
      unless version.reify.nil?
        comments_made << version.reify.comments
      end
    end
    return comments_made
  end

  def get_updated_by

    updated_by = []

    self.versions.each do |version|
      unless version.reify.nil?
        updated_by << version.reify.last_updated_by_user.fullname
      end
    end
    return updated_by
  end

  def get_update_time

    update_time = []

    self.versions.each do |version|
      unless version.reify.nil?
        update_time << version.reify.last_updated_at.strftime('%d %B %Y (%I:%M%P)')
      end
    end
    return update_time
  end



  def is_break_approver?
    if self.current_user.fullname=='Super admin ' || (self.current_user.is? :pcc_break_approver, :in_group => [:pcc_requests])
      return true
    else
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
  end



  def is_requester?
    if User.current_user==self.requester
      return true
    else
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
  end
  def store_requester(user)
self.requester=user
    self.requester.save
  end
  def friendly_name
    ("#%d %s" % [self.id, self.purpose])
  end

  def url
    Rails.application.routes.url_helpers.pcc_break_request_url(self)
  end

  def friendly_first_name_for_email
    "PccBreakRequest ##{self.id}"
  end

  def friendly_second_name_for_email
    ""
  end

  def friendly_name_for_sms
    "PccBreakRequest ##{self.id} "
  end

  def can_create?
    return true if User.current_user.is? :any, :in_group => [:pcc_requests]
    return false
  end

  def can_view?
   if  (User.current_user.is? :pcc_break_approver) or (User.current_user.is? :super_admin) or (self.requester==User.current_user)
     return true
   end
    return false
  end



  def event_name
    if(self.last_update==' pending to need clarification')
      return "Clarification Requested"
    end
    if(self.last_update==' need clarification to pending')
      return "Clarified"
      end

    if(self.last_update==' pending to approved')
      return "Approved"
    end
    if(self.last_update==' pending to rejected')
      return "Rejected"
    end

    if(self.last_update==' pending to cancelled') or (self.last_update==' approved to cancelled') or (self.last_update==' need_clarification to cancelled')
      return "Cancelled"
    end
=begin
    else
     if(self.state=='booked')
      "Booked"
      else
      if(self.state=='cancelled')
      "Cancelled"
      end
    end
=end
  end

end
