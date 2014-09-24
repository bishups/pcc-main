class PccBreakRequestsController < ApplicationController
  # GET /pcc_break_requests
  # GET /pcc_break_requests.json
  before_filter :authenticate_user!
  def index
    if(User.current_user.is? :pcc_break_approver, :in_group => [:pcc_requests])
    @pcc_break_requests = PccBreakRequest.all
    else
      @pcc_break_requests=PccBreakRequest.where('requester_id=?',current_user.id)
    end

    #value ={:send_sms => true, :send_email => true,:additional_text =>nil}
    # notify[requester]=value
    respond_to do |format|
      if User.current_user.is? :any, :in_group => [:pcc_requests]
        format.html # index.html.erb
        format.json { render json: @pcc_break_requests }
      else
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_break_requests.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /pcc_break_requests/1
  # GET /pcc_break_requests/1.json
  def show
    @pcc_break_request = PccBreakRequest.find(params[:id])

    @pcc_break_request.requester=User.find(@pcc_break_request.requester_id)
    @pcc_break_request.current_user = current_user

    respond_to do |format|
      if @pcc_break_request.can_view?
        format.html # show.html.erb
        format.json { render json: @pcc_break_request }
      else
        format.html { redirect_to pcc_break_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_break_requests.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /pcc_break_requests/new
  # GET /pcc_break_requests/new.json
  def new
    @pcc_break_request = PccBreakRequest.new


    respond_to do |format|
      if @pcc_break_request.can_create?
        format.html # new.html.erb
        format.json { render json: @pcc_break_request }

      else
        format.html { redirect_to pcc_break_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_break_requests.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /pcc_break_requests/1/edit
  def edit
    @pcc_break_request = PccBreakRequest.find(params[:id])

    @trigger = params[:trigger]
    @pcc_break_request.comment_category = Comment.where('model = ? AND action = ?', 'PccBreakRequest', @trigger).pluck(:text)

    respond_to do |format|

      format.html
      format.json { render json: @pcc_break_request}

    end
  end

  def edit_break_request
    @pcc_break_request = PccBreakRequest.find(params[:id])
    respond_to do |format|
      if @pcc_break_request.can_update?
        format.html
        format.json { render json: @pcc_break_request}
      else
        format.html { redirect_to pcc_break_requests_url, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @pcc_break_requests.errors, status: :unprocessable_entity }
      end

    end
  end
  # POST /pcc_break_requests
  # POST /pcc_break_requests.json
  def create
    @pcc_break_request = PccBreakRequest.new(params[:pcc_break_request])
    @pcc_break_request.store_requester(current_user)
    @pcc_break_request.requester_id=current_user.id
    @pcc_break_request.mark_as_pending!
    errors=false
    if(@pcc_break_request.to!=nil and @pcc_break_request.from!=nil)
      @pcc_break_request.days=(@pcc_break_request.to-@pcc_break_request.from).to_i
      error1=(@pcc_break_request.from-Date.today).to_i<0
      error2=@pcc_break_request.days<0
      if error1 or error2
        errors=true
      end
    end

    #@pcc_break_request.timestamp=Time.now
    respond_to do |format|
      if errors
       if  error1
       format.html { redirect_to new_pcc_break_request_path, alert: 'From Date should be greater than Today\'s Date'}
       end

       if  error2
         format.html { redirect_to new_pcc_break_request_path, alert: 'From Date should be less than To Date' }
       end
      else

      if @pcc_break_request.save
        break_approver=[]
        break_approver=@pcc_break_request.get_break_approver

        break_approver.each { |break_approver|
          unless (break_approver.empty?)
            UserMailer.new_break_request_email(@pcc_break_request,break_approver[0]).deliver
            UserMailer.new_break_request_sms(@pcc_break_request,break_approver[0]).deliver
          end
        }

        format.html { redirect_to @pcc_break_request, notice: 'Pcc break request was successfully created.' }
        format.json { render json: @pcc_break_request, status: :created, location: @pcc_break_request }
      else
        format.html { render action: "new" }
        format.json { render json: @pcc_break_request.errors, status: :unprocessable_entity }
      end
      end
    end



  end

  # PUT /pcc_break_requests/1
  # PUT /pcc_break_requests/1.json
  def update
    @pcc_break_request = PccBreakRequest.find(params[:id])
    @pcc_break_request.current_user=current_user
    @trigger = params[:trigger]
    @pcc_break_request.load_comments!(params)





        if(@trigger!="" and @trigger!=nil)
        if state_update(@pcc_break_request, @trigger) &&  @pcc_break_request.save!
          respond_to do |format|
          format.html { redirect_to @pcc_break_request, notice: 'PCC Break Request was successfully updated.' }
          format.json { render json: @pcc_break_request }
          end
        else
          respond_to do |format|
          format.html { render :action => 'edit' }
          format.json { render json: @pcc_break_request.errors, status: :unprocessable_entity }
          end
        end



        else



       if @pcc_break_request.update_attributes(params[:pcc_break_request])

        @pcc_break_request.update_attribute('days',(@pcc_break_request.to-@pcc_break_request.from).to_i)
        update_tag=true
       end





      if(@pcc_break_request.to!=nil and @pcc_break_request.from!=nil)


        error1=(@pcc_break_request.from-Date.today).to_i<0
        error2=@pcc_break_request.days<0

        if error1 or error2
          errors=true
        end
      end


        if errors

          respond_to do |format|

          if  error1

            format.html { redirect_to edit_break_request_pcc_break_request_path, alert: 'From Date should be greater than Today\'s Date'}

          end

          if  error2

            format.html { redirect_to edit_break_request_pcc_break_request_path, alert: 'From Date should be less than To Date' }

          end

          end

        else
          if update_tag
            respond_to do |format|
            format.html { redirect_to @pcc_break_request, notice: 'PCC Break Request was successfully updated.' }
            format.json { render json: @pcc_break_request }
            approver=@pcc_break_request.get_break_approver
            approver.each { |break_approver|
              if (break_approver!= nil)
                UserMailer.edit_pcc_request_email(@pcc_break_request, break_approver[0]).deliver
                UserMailer.edit_pcc_request_sms(@pcc_break_request, break_approver[0]).deliver
              end
            }
            end
          else

            respond_to do |format|
              format.html { redirect_to edit_break_request_pcc_break_request_path }
              format.json { render json: @pcc_break_request.errors, status: :unprocessable_entity }
            end
          end


       end
      end

      end

  # DELETE /pcc_break_requests/1
  # DELETE /pcc_break_requests/1.json
  def destroy
    @pcc_break_request = PccBreakRequest.find(params[:id])
    @pcc_break_request.destroy

    respond_to do |format|
      format.html { redirect_to pcc_break_requests_url }
      format.json { head :no_content }
    end
  end


  def state_update(ptr, trig)
    if ::PccBreakRequest::PROCESSABLE_EVENTS.include?(@trigger)
      ptr.send(trig)
    end
  end
end

