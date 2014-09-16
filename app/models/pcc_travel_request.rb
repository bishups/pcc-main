class PccTravelRequest < ActiveRecord::Base
  include CommonFunctions

#has_one :ticket, :class_name=>Ticket

  attr_accessor :current_user
  attr_accessible :reachbefore,:preferred_clss, :doj, :from, :idproof, :idproofnumber, :mode, :purpose, :tatkal, :timefrom, :timeto, :to,:requester_id

  belongs_to :last_updated_by_user, :class_name => User
  belongs_to :requester, :class_name => User
  attr_accessor :comment_category
  attr_accessible :comment_category
  attr_accessible :last_update, :last_updated_at, :upload_ticket, :test
  validates_presence_of :reachbefore,:message=>"Reach Before field can't be empty."
  validates_presence_of :preferred_clss,:message=>"Preferred Class field can't be empty."
  validates_presence_of :doj,:message=> "Date Of Journey field can't be empty."
  validates_presence_of :idproofnumber,:message=>"Id Proof Number field can't be empty."
  validates_presence_of :purpose,:message=>"Purpose field can't be empty."
  validates_presence_of :to,:message=>"To field can't be empty."
  validates_presence_of :from,:message=>"From field can't be empty."
  after_create :mark_as_pending!


  #attr_accessible :attachment, :ticket_name
  #mount_uploader :attachment, AttachmentUploader # Tells rails to use this uploader for this model.
  has_one :travel_ticket, :class_name =>TravelTicket
 # validates :idproofnumber, :numericality => {:only_integer => true }
  has_paper_trail
  has_paper_trail :on => [:update]
  has_paper_trail :only => [:last_updated_by_user,:last_update,:last_updated_at,:comments]
  STATE_NEW= "new"
  STATE_PENDING         = "pending"
  STATE_BOOKED        = "booked"
  STATE_NEED_CLARIFICATION = "need clarification"
  STATE_NEED_APPROVAL= "need approval"
  STATE_CANCELLATION_REQUESTED="cancellation requested"
  STATE_WITHDRAWN="withdrawn"
  STATE_APPROVED="approved"
  STATE_REJECTED="rejected"
  STATE_CANCELLED="cancelled"
  STATE_TICKET_UPLOADED="ticket uploaded"
  STATE_UNKNOWN="unknown"

  FINAL_STATES = [STATE_WITHDRAWN,STATE_REJECTED,STATE_CANCELLED]
  EVENT_BOOK         = "Book"
  EVENT_REQUEST ="Request"
  EVENT_REQUEST_CLARIFICATION="Request Clarification"
  EVENT_CLARIFY="clarify"
  EVENT_REQUEST_APPROVAL="request approval"
  EVENT_APPROVE="approve"
  EVENT_REJECT="reject"
  EVENT_WITHDRAW="Withdraw Request"
  EVENT_REQUEST_CANCELLATION="request cancellation"
  EVENT_CANCEL="cancel"

  PROCESSABLE_EVENTS = [
      EVENT_CANCEL,EVENT_REQUEST_CANCELLATION, EVENT_WITHDRAW, EVENT_REQUEST,  EVENT_BOOK, EVENT_REQUEST_CLARIFICATION, EVENT_CLARIFY, EVENT_REQUEST_APPROVAL,  EVENT_APPROVE, EVENT_REJECT
  ]
  EVENTS_WITH_COMMENTS = [EVENT_REQUEST_CANCELLATION,EVENT_REJECT, EVENT_REQUEST_CLARIFICATION, EVENT_CLARIFY]
  EVENTS_WITH_FEEDBACK=[]
  EVENTS_FOR_APPROVER=[EVENT_REQUEST_APPROVAL,EVENT_APPROVE,EVENT_REJECT]
  EVENTS_FOR_VENDOR=[EVENT_APPROVE,EVENT_BOOK,EVENT_REQUEST_CANCELLATION,EVENT_CANCEL]
  STATES_FOR_APPROVER=[STATE_APPROVED,STATE_REJECTED,STATE_NEED_APPROVAL]
  STATES_FOR_VENDOR=[STATE_APPROVED,STATE_BOOKED,STATE_CANCELLATION_REQUESTED,STATE_CANCELLED,STATE_TICKET_UPLOADED]
  state_machine :state, :initial => STATE_UNKNOWN do

    event EVENT_REQUEST do
      transition STATE_UNKNOWN => STATE_PENDING #, :if => lambda {|t| t.can_create?}
    end

    event EVENT_APPROVE do
      transition STATE_PENDING => STATE_APPROVED ,:if => lambda {|t| t.is_pcc_travel?}
      transition STATE_NEED_APPROVAL => STATE_APPROVED ,:if => lambda {|t| t.is_travel_approver?}
    end
    before_transition STATE_PENDING => STATE_APPROVED, :do => :is_pcc_travel?
    before_transition STATE_NEED_APPROVAL => STATE_APPROVED, :do => :is_travel_approver?

    event EVENT_REQUEST_CLARIFICATION do
      transition STATE_PENDING => STATE_NEED_CLARIFICATION,:if => lambda {|t| t.is_pcc_travel?}
    end
    before_transition STATE_PENDING => STATE_NEED_CLARIFICATION, :do => :is_pcc_travel?

    event EVENT_CLARIFY do
      transition STATE_NEED_CLARIFICATION => STATE_PENDING,:if => lambda {|t| t.is_requester?}
    end
    before_transition STATE_NEED_CLARIFICATION => STATE_PENDING, :do => :is_requester?


    event EVENT_REQUEST_APPROVAL do
      transition STATE_PENDING => STATE_NEED_APPROVAL,:if => lambda {|t| t.is_pcc_travel?}
    end
    before_transition STATE_PENDING => STATE_NEED_APPROVAL, :do => :is_pcc_travel?

    event EVENT_REJECT do
      transition STATE_NEED_APPROVAL => STATE_REJECTED, :if => lambda {|t| t.is_travel_approver?}
    end
    before_transition STATE_NEED_APPROVAL => STATE_REJECTED, :do => :is_travel_approver?

    event EVENT_WITHDRAW do
      transition [STATE_PENDING,STATE_NEED_CLARIFICATION,STATE_NEED_APPROVAL,STATE_APPROVED]  => STATE_WITHDRAWN, :if => lambda {|t| t.is_requester?}

    end
    before_transition [STATE_PENDING,STATE_NEED_CLARIFICATION,STATE_NEED_APPROVAL,STATE_APPROVED ] => STATE_WITHDRAWN, :do => :is_requester?

    event EVENT_REQUEST_CANCELLATION do
      transition STATE_BOOKED => STATE_CANCELLATION_REQUESTED, :if => lambda {|t| t.is_requester?}
      transition STATE_TICKET_UPLOADED => STATE_CANCELLATION_REQUESTED, :if => lambda {|t| t.is_requester?}
    end
    before_transition STATE_BOOKED => STATE_CANCELLATION_REQUESTED, :do => :is_requester?
    before_transition STATE_TICKET_UPLOADED => STATE_CANCELLATION_REQUESTED, :do => :is_requester?

    event EVENT_CANCEL do
      transition STATE_CANCELLATION_REQUESTED => STATE_CANCELLED, :if => lambda {|t| t.is_pcc_travel_vendor?}
    end
    before_transition STATE_CANCELLATION_REQUESTED => STATE_CANCELLED, :do => :is_pcc_travel_vendor?

    event EVENT_BOOK do
      transition STATE_APPROVED => STATE_BOOKED, :if => lambda {|t| t.is_pcc_travel_vendor?}
    end
    before_transition STATE_APPROVED => STATE_BOOKED, :do => :is_pcc_travel_vendor?

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
    travel_incharge=object.get_travel_incharge
    approver=object.get_travel_approver
    vendor=object.get_travel_vendor


    value = {:send_sms => true, :send_email => true, :additional_text => nil }
    travel_incharge.each { |travel_incharge|
      unless (travel_incharge.empty?)
        UserMailer.email(object, travel_incharge[0], transition.from, transition.to, transition.event, nil).deliver
        UserMailer.sms(object, travel_incharge[0], transition.from, transition.to, transition.event, nil).deliver
        object.log_notify(travel_incharge[0], transition.from, transition.to, transition.event, nil)
        object.log_last_activity(travel_incharge[0], transition.from, transition.to, transition.event)
      end
    }

    if(transition.event==EVENT_REQUEST_APPROVAL)

    approver.each { |travel_approver|
      if (travel_approver!= nil)
        UserMailer.email(object, travel_approver[0], transition.from, transition.to, transition.event, 'Please Approve!').deliver
        UserMailer.sms(object, travel_approver[0], transition.from, transition.to, transition.event, 'Please Approve!').deliver
        object.log_notify(travel_approver[0], transition.from, transition.to, transition.event, 'Please Approve!')
        object.log_last_activity(travel_approver[0], transition.from, transition.to, transition.event)
      end
    }
    end

    if(transition.event==EVENT_REQUEST_CANCELLATION or transition.event==EVENT_APPROVE or transition.event==EVENT_BOOK or transition.event==EVENT_CANCEL)

      vendor.each { |travel_vendor|
        if (travel_vendor!= nil)
          UserMailer.email(object, travel_vendor[0], transition.from, transition.to, transition.event, nil).deliver
          UserMailer.sms(object, travel_vendor[0], transition.from, transition.to, transition.event, nil).deliver
          object.log_notify(travel_vendor[0], transition.from, transition.to, transition.event, nil)
          object.log_last_activity(travel_vendor[0], transition.from, transition.to, transition.event)
        end
      }
    end
    UserMailer.email(object, requester, transition.from, transition.to, transition.event, nil).deliver
    UserMailer.sms(object, requester, transition.from, transition.to, transition.event, nil).deliver
    object.log_notify(requester, transition.from, transition.to, transition.event, nil)
    object.log_last_activity(requester, transition.from, transition.to, transition.event)
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
self.log_activity_for_create_edit(self.requester,'create')
    self.log_notify_for_create_edit(self.requester,'create')
  end


  def get_travel_incharge
    pcc_travel_roles=[]
    travel_incharge=[]
    pcc_travel_roles=Role.find_all_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_travel][:text])
    i=0
    pcc_travel_roles.each { |pcc_travel_role|
      role_id=pcc_travel_role.id
      if(!(Role.find(role_id).users).empty?)
        travel_incharge[i]=Role.find(role_id).users
        i=i+1
      end
    }
    return travel_incharge
  end

  def get_travel_approver
    pcc_travel_approver_roles=[]
    travel_approver=[]
    pcc_travel_approver_roles=Role.find_all_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_travel_approver][:text])
    i=0
    pcc_travel_approver_roles.each { |pcc_travel_approver_role|
      role_id=pcc_travel_approver_role.id
      if(!(Role.find(role_id).users).empty?)
        travel_approver[i]=Role.find(role_id).users
        i=i+1
      end
    }
    return travel_approver
  end

  def get_travel_vendor
    pcc_travel_vendor_roles=[]
    travel_vendor=[]
    pcc_travel_vendor_roles=Role.find_all_by_name(::User::ROLE_ACCESS_HIERARCHY[:pcc_travel_vendor][:text])
    i=0
    pcc_travel_vendor_roles.each { |pcc_travel_vendor_role|
      role_id=pcc_travel_vendor_role.id
      if(!(Role.find(role_id).users).empty?)
        travel_vendor[i]=Role.find(role_id).users
        i=i+1
      end
    }
    return travel_vendor
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

  def is_pcc_travel?
    if self.current_user.fullname=='Super admin ' || (self.current_user.is? :pcc_travel, :in_group => [:pcc_requests])
      return true
    else
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
  end


  def is_travel_approver?
    if self.current_user.fullname=='Super admin ' || (self.current_user.is? :pcc_travel_approver, :in_group => [:pcc_requests])
      return true
    else
      self.errors[:base] << "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access."
      return false
    end
  end

  def is_pcc_travel_vendor?
    if self.current_user.fullname=='Super admin ' || (self.current_user.is? :pcc_travel_vendor, :in_group => [:any])
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
    Rails.application.routes.url_helpers.pcc_travel_request_url(self)
  end

  def friendly_first_name_for_email
    "PccTravelRequest ##{self.id} by #{self.requester.fullname}"
  end

  def friendly_second_name_for_email
    ""
  end

  def friendly_name_for_sms
    "PccTravelRequest ##{self.id} "
  end

  def can_create?
    return true if User.current_user.is? :any, :in_group => [:pcc_requests]
    return false
  end

  def can_view?
   if  (User.current_user.is? :pcc_travel) or (User.current_user.is? :super_admin) or (self.requester==User.current_user) or (( User.current_user.is? :pcc_travel_approver) and (STATES_FOR_APPROVER.include? self.state)) or((User.current_user.is? :pcc_travel_vendor)and (STATES_FOR_VENDOR.include? self.state))
     return true
   end
    return false
  end

  def can_update?
    return true if self.is_requester? and !(['approved','booked','cancellation requested','cancelled','rejected','ticket uploaded'].include? self.state)
    return false

  end

  def can_change_state?

  end

  def event_name
    if(self.last_update==' pending to need clarification')
      return "Clarification Requested"
    end
    if(self.last_update==' need clarification to pending')
      return "Clarified"
      end
    if(self.last_update==' pending to need approval')
      return "Approval Requested"
      end
    if(self.last_update==' need approval to approved')
      return "Approved"
    end
    if(self.last_update==' pending to approved')
      return "Approved"
    end
    if(self.last_update==' need approval to rejected')
      return "Rejected"
    end
    if(self.last_update==' approved to booked')
      return "Booked"
    end

    if(self.last_update==' pending to withdrawn')
      return "Ticket Request Withdrawn"
    end
    if(self.last_update==' need clarification to withdrawn')
      return "Ticket Request Withdrawn"
    end
    if(self.last_update==' need approval to withdrawn')
      return "Ticket Request Withdrawn"
    end
    if(self.last_update==' approved to withdrawn')
      return "Ticket Request Withdrawn"
    end
    if(self.last_update==' booked to cancellation requested')
      return "Cancellation Requested"
    end
    if(self.last_update==' cancellation requested to cancelled')
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

  def log_activity_for_create_edit(user,op, date = Time.zone.now)
    activity = ::ActivityLog.new
    activity.user = user
    activity.model_type = self.class.name
    #activity.model_type = "ProgramTeacherSchedule" if activity.model_type == "TeacherSchedule" and !self.program.nil?
    #activity.model_type = "TeacherSchedule" if activity.model_type == "ProgramTeacherSchedule" and self.program.nil?
    activity.model_id =  self.id
    activity.date = date.nil? ? Time.zone.now : date
    activity.text1 = self.friendly_first_name_for_email
    if(op=='create')
    activity.text2 = "New Request"
    else
      activity.text2 = "Edited #{ self.friendly_first_name_for_email}"
      end
    # user, date, model_id, model_type, text
    activity.save
    unless activity.errors.nil?
      # TODO - some error handling or log msg?
    end
  end

  def log_notify_for_create_edit(user,op)
    notification = ::NotificationLog.new
    notification.user = user
    notification.model_type = self.class.name
    #notification.model_type = "ProgramTeacherSchedule" if notification.model_type == "TeacherSchedule" and !self.program.nil?
    #notification.model_type = "TeacherSchedule" if notification.model_type == "ProgramTeacherSchedule" and self.program.nil?
    notification.model_id = self.id
    notification.date = Time.zone.now
    notification.text1 = self.friendly_first_name_for_email
    if(op=='create')
      notification.text2 = "New Request"
    else
      notification.text2 = "Edited #{ self.friendly_first_name_for_email}"
    end
    # user, date, model_id, model_type, text
    notification.save
    unless notification.errors.nil?
      # TODO - some error handling or log msg?
    end
  end
end
