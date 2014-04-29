class KitSchedulesController < ApplicationController
  # GET /kit_schedules
  # GET /kit_schedules.json
  before_filter :authenticate_user!
  #before_filter :load_kit!
  
  def index
    @kit = ::Kit.find(params[:kit_id].to_i)
    @kit.current_user = current_user
    @kit_schedules = @kit.kit_schedules.where(['end_date > ? OR state NOT IN (?) ', (Time.zone.now - 1.month.from_now), ::KitSchedule::FINAL_STATES]).order('start_date ASC')

    respond_to do |format|
      if @kit.can_view_schedule?
        format.html # index.html.erb
        format.json { render json: @kit_schedules }
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit.errors, status: :unprocessable_entity }
      end
     end
  end

  # GET /kit_schedules/1
  # GET /kit_schedules/1.json
  def show
    @kit_schedule = KitSchedule.find(params[:id])
    @kit_schedule.current_user = current_user

    respond_to do |format|
      if @kit_schedule.can_update?
        format.html # show.html.erb
        format.json { render json: @kit_schedule }
      else
        format.html { redirect_to kits_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /kit_schedules/new
  # GET /kit_schedules/new.json
  def new
    @kit = ::Kit.find(params[:kit_id].to_i) if params.has_key?(:kit_id)
    @kit_schedule = KitSchedule.new
    @kit_schedule.current_user = current_user

    if params.has_key?(:kit_id)
      @kit_schedule.kit_id = params[:kit_id]
      center_ids = @kit_schedule.kit.center_ids
    end

    if params.has_key?(:program_id)
      @kit_schedule.program_id = params[:program_id]
      center_ids = @kit_schedule.program.center_id
    end

    respond_to do |format|
      if @kit_schedule.can_create?(center_ids)
        format.html
        format.json { render json: @kit_schedule }
      else
        if @kit_schedule.kit_id.nil?
          format.html { redirect_to program_path(params[:program_id]), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        else
          format.html { redirect_to kit_schedules_path(:kit_id => @kit), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        end
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def reserve
    @kit = Kit.find(params[:id].to_i)
    @trigger = params[:trigger]
    @kit_schedule = KitSchedule.new
    @kit_schedule.current_user = current_user
    @kit_schedule.kit_id = @kit.id
    @kit_schedule.comment_category = Comment.where('model IS ? AND action IS ?', 'KitSchedule', @trigger).pluck(:text)

    respond_to do |format|
      if @kit_schedule.can_create_on_trigger?
        format.html { render action: "reserve" }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      else
        format.html { redirect_to kit_schedules_path(:kit_id => @kit_schedule.kit_id), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /kit_schedules/1/edit
  def edit
    @kit_schedule = KitSchedule.find(params[:id])
    @kit_schedule.current_user = current_user

    @trigger = params[:trigger]
    @kit_schedule.comment_category = Comment.where('model IS ? AND action IS ?', 'KitSchedule', @trigger).pluck(:text)

    respond_to do |format|
      if @kit_schedule.can_update?
        format.html
        format.json { render json: @kit_schedule }
      else
        format.html { redirect_to kit_schedules_path(:kit_id => @kit_schedule.kit), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end


  def create_on_trigger
    @kit_schedule = KitSchedule.new(params[:kit_schedule])
    @kit = @kit_schedule.kit
    @kit_schedule.current_user = current_user
    @trigger = params[:trigger]
    @kit_schedule.load_comments!(params)

    respond_to do |format|
      if @kit_schedule.can_create_on_trigger?
        if @kit_schedule.send(@trigger) && @kit_schedule.save
          format.html { redirect_to kit_schedules_path(:kit_id => @kit.id)}
          format.json { render json: @kit_schedule, status: :created, location: @kit_schedule }
        else
          format.html { render action: 'reserve' }
          format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to kit_schedules_path(:kit_id => @kit.id), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end



  # POST /kit_schedules
  # POST /kit_schedules.json
  def create
    # In case it is a reserve/ overdue/ or under-repair schedule, call relevant handler
    if params.has_key?('trigger')
      return create_on_trigger
    end

    # TODO - fix this hack to initialize @venue on create from fix _form.html.erb to pass correct params :-(
    if params.has_key?(:kit_id)
      kit_id = params[:kit_id].to_i
    elsif params.has_key?(:kit_schedule)
      kit_id = (params[:kit_schedule][:kit_id]).to_i  if params[:kit_schedule].has_key?(:kit_id)
    end

    @kit = ::Kit.find(kit_id)
    @kit.current_user = current_user
    @kit_schedule = @kit.kit_schedules.new(params[:kit_schedule])
    @kit_schedule.current_user = current_user

    respond_to do |format|
      if @kit_schedule.can_create?
        if @kit_schedule.send(::KitSchedule::EVENT_BLOCK) && @kit_schedule.save
          format.html { redirect_to @kit_schedule, notice: 'Kit schedule was successfully created.'}
          format.json { render json: @kit_schedule, status: :created, location: @kit_schedule }
        else
          #render :action => 'new'
          format.html { render action: "new" }
          format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to kit_schedules_path(:kit_id => @kit_schedule.kit), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end




  # PUT /kit_schedules/1
  # PUT /kit_schedules/1.json
  def update

    @kit_schedule = KitSchedule.find(params[:id])
    @kit_schedule.current_user = current_user
    @trigger = params[:trigger]

    @kit_schedule.load_comments!(params)
    @kit_schedule.issued_to = params[:issued_to] unless params[:issued_to].nil?
#    @kit_schedule.due_date_time = params[:due_date_time] unless params[:due_date_time].nil?
#    @kit_schedule.issue_for_schedules = params[:issue_for_schedules].split(' ').map(&:to_i) unless params[:issue_for_schedules].nil?

    respond_to do |format|

      if @kit_schedule.can_update?
        if state_update(@kit_schedule, @trigger) &&  @kit_schedule.save!
          format.html { redirect_to [@kit,@kit_schedule], notice: 'Kit Schedule was successfully updated.' }
          format.json { render :json => @kit_schedule }
        else
          format.html { render :action => 'edit' }
          format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to kit_schedules_path(:kit_id => @kit_schedule.kit), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kit_schedules/1
  # DELETE /kit_schedules/1.json
  def destroy
    # not allowing to delete for now

    @kit_schedule = KitSchedule.find(params[:id])
    @kit_schedule.current_user = current_user

    # only users making reserve call can delete the corresponding reserved schedules
    if @kit_schedule.can_delete?
      kit_id = @kit_schedule.kit_id
      @kit_schedule.destroy
      respond_to do |format|
          format.html { redirect_to kit_schedules_path(:kit_id => kit_id) }
          format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to kit_schedules_path(:kit_id => @kit_schedule.kit_id), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  #def load_kit!
  #  @kit = ::Kit.find(params[:kit_id].to_i)
  #end

   def state_update(ks, trig)
    if ::KitSchedule::PROCESSABLE_EVENTS.include?(trig)
      ks.send(trig)
    else
      ks.errors[:base] << "Received invalid event - #{trig}."
      return false
    end
   end


end
