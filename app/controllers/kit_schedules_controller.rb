class KitSchedulesController < ApplicationController

  # GET /kit_schedules
  # GET /kit_schedules.json
  before_filter :authenticate_user!
  #before_filter :load_kit!
  
  def index
    @kit = ::Kit.find(params[:kit_id].to_i)
    @kit_schedules = @kit.kit_schedules.where(['start_date > ?', Time.zone.now])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @kit_schedules }
    end
  end

  # GET /kit_schedules/1
  # GET /kit_schedules/1.json
  def show
    @kit_schedule = KitSchedule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @kit_schedule }
    end
  end

  # GET /kit_schedules/new
  # GET /kit_schedules/new.json
  def new
    @kit = ::Kit.find(params[:kit_id].to_i) if params.has_key?(:kit_id)
    @kit_schedule = KitSchedule.new

    @kit_schedule.program_id = params[:program_id] if params.has_key?(:program_id)
    @kit_schedule.kit_id = params[:venue_id] if params.has_key?(:kit_id)


    respond_to do |format|
      format.html 
      format.json { render json: @kit_schedule }
    end
  end

  def reserve
    @kit = Kit.find(params[:id].to_i)
    @trigger = params[:trigger]
    @kit_schedule = KitSchedule.new
    @kit_schedule.kit_id = @kit.id

    respond_to do |format|
      format.html { render action: "reserve" }
      format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
    end
  end

  # GET /kit_schedules/1/edit
  def edit
    @kit_schedule = KitSchedule.find(params[:id])

    @trigger = params[:trigger]

    respond_to do |format|
      format.html
      format.json { render json: @kit_schedule }
    end
  end


  def create_on_trigger
    @kit_schedule = KitSchedule.new(params[:kit_schedule])
    @kit = @kit_schedule.kit
    @trigger = params[:trigger]

    respond_to do |format|
      format.html do
        if @kit_schedule.send(@trigger)
          if @kit_schedule.save!
            redirect_to kit_schedules_path(:kit_id => @kit.id)
          end
        else
          render :action => 'reserve'
        end
      end

      format.json { render :json => @kit_schedule }
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
    @kit_schedule = @kit.kit_schedules.new(params[:kit_schedule])
    @kit_schedule.current_user = current_user

    respond_to do |format|
      format.html do
        # also block the kit
        if @kit_schedule.send(::KitSchedule::EVENT_BLOCK)
          if @kit_schedule.save
            redirect_to @kit_schedule, notice: 'Kit schedule was successfully created.'
            format.json { render json: @kit_schedule, status: :created, location: @kit_schedule }
          else
            render :action => 'new'
            #format.html { render action: "new" }
            format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
          end
        else
          render :action => 'new'
          #format.html { render action: "new" }
          format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
        end
      end
    end
  end




  # PUT /kit_schedules/1
  # PUT /kit_schedules/1.json
  def update

    @kit_schedule = KitSchedule.find(params[:id])
    @trigger = params[:trigger]
    @kit_schedule.comments = params[:comment]

    @kit_schedule.issued_to = params[:issued_to] unless params[:issued_to].nil?
    @kit_schedule.due_date_time = params[:due_date_time] unless params[:due_date_time].nil?
    @kit_schedule.comments = params[:comments] unless params[:comments].nil?
    @kit_schedule.issue_for_schedules = params[:issue_for_schedules].split(' ').map(&:to_i) unless params[:issue_for_schedules].nil?
    @kit_schedule.current_user = current_user

    respond_to do |format|
      format.html do
        if state_update(@kit_schedule, @trigger)
          if @kit_schedule.save!
            #redirect_to action: "edit" , :trigger => params[:trigger]
            redirect_to [@kit,@kit_schedule]
          end
        else
            render :action => 'edit'
        end
      end

      format.json { render :json => @kit_schedule }
    end
  end

  # DELETE /kit_schedules/1
  # DELETE /kit_schedules/1.json
  def destroy
    @kit_schedule = KitSchedule.find(params[:id])
    kit_id = @kit_schedule.kit_id
    @kit_schedule.destroy

    respond_to do |format|
      format.html { redirect_to kit_schedules_path(:kit_id => kit_id) }
      format.json { head :no_content }
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
