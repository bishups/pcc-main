class PccTravelRequestsController < ApplicationController
  # GET /pcc_travel_requests
  # GET /pcc_travel_requests.json
  before_filter :authenticate_user!
  def index
    if(User.current_user.is? :pcc_travel, :in_group => [:pcc_requests]) #Travel Incharge
    @pcc_travel_requests = PccTravelRequest.all
   else
    if(User.current_user.is? :pcc_travel_approver, :in_group => [:pcc_requests]) #Travel Approver
      @pcc_travel_requests = PccTravelRequest.find_all_by_state(['approved', 'rejected', 'need approval'])
    end
    if(User.current_user.is? :pcc_travel_vendor, :in_group => [:pcc_travel_vendor]) #Travel Vendor
      @pcc_travel_requests = PccTravelRequest.find_all_by_state(['approved','cancellation requested','booked','cancelled','ticket uploaded'])
    end

    if(User.current_user.is? :any, :in_group => [:pcc_requests] and  !PccTravelRequest.find_all_by_requester_id(User.current_user.id).empty?)  #PCC Requester. Show only his requests.
      if(@pcc_travel_requests!=nil )

      @pcc_travel_requests.concat( PccTravelRequest.find_all_by_requester_id(User.current_user.id))   #Might overlap with above roles, so concat
      else
        @pcc_travel_requests = PccTravelRequest.find_all_by_requester_id(User.current_user.id)

      end
    end
    end


       respond_to do |format|
      if User.current_user.is? :any, :in_group => [:pcc_requests] or User.current_user.is? :pcc_travel_vendor
      format.html # index.html.erb
      format.json { render json: @pcc_travel_requests }
      else
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }
        end
    end
  end

  # GET /pcc_travel_requests/1
  # GET /pcc_travel_requests/1.json
  def show
    @pcc_travel_request = PccTravelRequest.find(params[:id])

    @pcc_travel_request.requester=User.find(@pcc_travel_request.requester_id)
    @pcc_travel_request.current_user = current_user

    respond_to do |format|
      if @pcc_travel_request.can_view?
      format.html # show.html.erb
      format.json { render json: @pcc_travel_request }
      else
        format.html { redirect_to pcc_travel_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /pcc_travel_requests/new
  # GET /pcc_travel_requests/new.json
  def new
    @pcc_travel_request = PccTravelRequest.new


    respond_to do |format|
      if @pcc_travel_request.can_create?
      format.html # new.html.erb
      format.json { render json: @pcc_travel_request }

      else
      format.html { redirect_to pcc_travel_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
      format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /pcc_travel_requests/1/edit
  def edit
    @pcc_travel_request = PccTravelRequest.find(params[:id])

    @trigger = params[:trigger]
    @pcc_travel_request.comment_category = Comment.where('model = ? AND action = ?', 'PccTravelRequest', @trigger).pluck(:text)

    respond_to do |format|

        format.html
        format.json { render json: @pcc_travel_request}

    end
  end

  def edit_travel_request
    @pcc_travel_request = PccTravelRequest.find(params[:id])
    respond_to do |format|

      if @pcc_travel_request.can_update?
      format.html
      format.json { render json: @pcc_travel_request}
      else
        format.html { redirect_to pcc_travel_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_travel_requests.errors, status: :unprocessable_entity }
      end

    end
  end
  # POST /pcc_travel_requests
  # POST /pcc_travel_requests.json
  def create
    @pcc_travel_request = PccTravelRequest.new(params[:pcc_travel_request])
    @pcc_travel_request.store_requester(current_user)
    @pcc_travel_request.requester_id=current_user.id
    @pcc_travel_request.mark_as_pending!
    @pcc_travel_request.timestamp=Time.now
    @pcc_travel_request.timeto = nil if params[:pcc_travel_request]["timeto(4i)"].blank? and params[:pcc_travel_request]["timeto(5i)"].blank?
    @pcc_travel_request.timefrom = nil if params[:pcc_travel_request]["timefrom(4i)"].blank? and params[:pcc_travel_request]["timefrom(5i)"].blank?
    errors=false
    if(@pcc_travel_request.doj!=nil and @pcc_travel_request.reachbefore!=nil)
    error1=((@pcc_travel_request.doj.to_time.to_i-Date.today.to_time.to_i )<0)
    error2=((@pcc_travel_request.reachbefore.to_time.to_i-@pcc_travel_request.doj.to_time.to_i )<0)
    if error1 or error2
    errors=true
    end
    end

    respond_to do |format|
      if errors
        if error1
        format.html { redirect_to new_pcc_travel_request_path, alert: 'Wrong Date Of Journey: Please Enter Again.'}
        end
        if error2
          format.html { redirect_to new_pcc_travel_request_path, alert: 'Reach Before Date and Time has to be later than Date Of Journey'}
        end

      else
      if @pcc_travel_request.save
        travel_incharge=[]
        travel_incharge=@pcc_travel_request.get_travel_incharge

        travel_incharge.each { |travel_incharge|
          unless (travel_incharge.empty?)
            UserMailer.new_travel_request_email(@pcc_travel_request,travel_incharge[0]).deliver
            UserMailer.new_travel_request_sms(@pcc_travel_request,travel_incharge[0]).deliver
          end
        }

        format.html { redirect_to @pcc_travel_request, notice: 'Pcc travel request was successfully created.' }
        format.json { render json: @pcc_travel_request, status: :created, location: @pcc_travel_request }
      else
        format.html { render action: "new" }
        format.json { render json: @pcc_travel_request.errors, status: :unprocessable_entity }
      end
     end
    end



  end
  #def filter_blank_timeto
  #  if params[:event]['timeto(4i)'].blank?
  #    params[:event]['timeto(1i)'] = ""
  #    params[:event]['timeto(2i)'] = ""
  #    params[:event]['timeto(3i)'] = ""
  #    params[:event]['timeto(4i)'] = ""
  #    params[:event]['timeto(5i)'] = ""
  #  end
  #end
  # PUT /pcc_travel_requests/1
  # PUT /pcc_travel_requests/1.json

  #Three Types of Update: 1) Upload Ticket 2) State Update 3)Edit Ticket Request Details
  def update
    @pcc_travel_request = PccTravelRequest.find(params[:id])
    @pcc_travel_request.current_user=current_user
    @trigger = params[:trigger]
    @pcc_travel_request.load_comments!(params)

    #Update Type 1
    if (@pcc_travel_request.state=='booked' and @pcc_travel_request.travel_ticket==nil and @trigger==nil)
      @pcc_travel_request.travel_ticket=TravelTicket.new
      return
    end

    #Update Type 2
    if(@trigger!="" and @trigger!=nil)
    respond_to do |format|

        if state_update(@pcc_travel_request, @trigger) &&  @pcc_travel_request.save!
          format.html { redirect_to @pcc_travel_request, notice: 'PCC Travel Request was successfully updated.' }
          format.json { render json: @pcc_travel_request }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @pcc_travel_request.errors, status: :unprocessable_entity }
        end

       end
    else

#Update Type 3
      if @pcc_travel_request.update_attributes(params[:pcc_travel_request])
        update_tag=true
        @pcc_travel_request.update_attribute('timeto' , nil) if params[:pcc_travel_request]["timeto(4i)"].blank? and params[:pcc_travel_request]["timeto(5i)"].blank?
        @pcc_travel_request.update_attribute('timefrom', nil) if params[:pcc_travel_request]["timefrom(4i)"].blank? and params[:pcc_travel_request]["timefrom(5i)"].blank?
      end





      if(@pcc_travel_request.doj!=nil and @pcc_travel_request.reachbefore!=nil)


        error1=((@pcc_travel_request.doj.to_time.to_i-Date.today.to_time.to_i )<0)
        error2=((@pcc_travel_request.reachbefore.to_time.to_i-@pcc_travel_request.doj.to_time.to_i )<0)

        if error1 or error2
          errors=true
        end
      end


      if errors

        respond_to do |format|

          if  error1

            format.html { redirect_to edit_travel_request_pcc_travel_request_path, alert: 'Wrong Date Of Journey: Please Enter Again.'}

          end

          if  error2

            format.html { redirect_to edit_travel_request_pcc_travel_request_path, alert: 'Reach Before Date and Time has to be later than Date Of Journey' }

          end

        end

      else
        if update_tag
          respond_to do |format|
            travel_incharge=@pcc_travel_request.get_travel_incharge
            travel_incharge.each { |travel_incharge|
              if (travel_incharge!= nil)
                UserMailer.edit_pcc_request_email(@pcc_travel_request, travel_incharge[0]).deliver
                UserMailer.edit_pcc_request_sms(@pcc_travel_request, travel_incharge[0]).deliver
              end
            }
            format.html { redirect_to @pcc_travel_request, notice: 'PCC Travel Request was successfully updated.' }
            format.json { render json: @pcc_travel_request }
            @pcc_travel_request.log_activity_for_create_edit(@pcc_travel_request.requester,'update')
            @pcc_travel_request.log_notify_for_create_edit(@pcc_travel_request.requester,'update')
            travel_incharge.each{|travel_incharge|
              if (travel_incharge!= nil)
            @pcc_travel_request.log_activity_for_create_edit( travel_incharge[0],'update')
            @pcc_travel_request.log_notify_for_create_edit( travel_incharge[0],'update')
            end
            }
          end
        else

          respond_to do |format|
            format.html { redirect_to edit_travel_request_pcc_travel_request_path }
            format.json { render json: @pcc_travel_request.errors, status: :unprocessable_entity }
          end
        end


      end
    end

  end

  # DELETE /pcc_travel_requests/1
  # DELETE /pcc_travel_requests/1.json
  def destroy
    @pcc_travel_request = PccTravelRequest.find(params[:id])
    @pcc_travel_request.destroy

    respond_to do |format|
      format.html { redirect_to pcc_travel_requests_url }
      format.json { head :no_content }
    end
  end

  def book
    @pcc_travel_request = PccTravelRequest.find(params[:id])
    @pcc_travel_request.mode="Booked"
    @pcc_travel_request.save
  end
  def state_update(ptr, trig)
    if ::PccTravelRequest::PROCESSABLE_EVENTS.include?(@trigger)
      ptr.send(trig)
    end
  end
  def upload_ticket
    @pcc_travel_request = PccTravelRequest.find(params[:id])

    @pcc_travel_request.travel_ticket=TravelTicket.new

  end

end
