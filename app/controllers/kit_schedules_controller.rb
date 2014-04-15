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

  # GET /kit_schedules/1/edit
  def edit
    @kit_schedule = KitSchedule.find(params[:id])

    @trigger = params[:trigger]

    respond_to do |format|
      format.html
      format.json { render json: @kit_schedule }
    end
  end

  # POST /kit_schedules
  # POST /kit_schedules.json
  def create
    # TODO - fix this hack to initialize @venue on create from fix _form.html.erb to pass correct params :-(
    if params.has_key?(:kit_id)
      kit_id = params[:kit_id].to_i
    elsif params.has_key?(:kit_schedule)
      kit_id = (params[:kit_schedule][:kit_id]).to_i  if params[:kit_schedule].has_key?(:kit_id)
    end

    @kit = ::Kit.find(kit_id)
    @kit_schedule = @kit.kit_schedules.new(params[:kit_schedule])
    @kit_schedule.set_up_details!

    respond_to do |format|
      if @kit_schedule.save
        format.html { redirect_to [@kit_schedule], notice: 'Kit schedule was successfully created.' }
        format.json { render json: @kit_schedule, status: :created, location: @kit_schedule }
      else
        format.html { render action: "new" }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /kit_schedules/1
  # PUT /kit_schedules/1.json
  def update

    @kit_schedule = KitSchedule.find(params[:id])
    @trigger = params[:trigger]
    @kit_schedule.comments = params[:comment]

    if !params[:issued_to_user_id].nil?
      @kit_schedule.issued_to_user_id = params[:issued_to_user_id]
    end

    if @trigger == "blocked"
      @kit_schedule.blocked_by_user_id = current_user.id
    end

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
    @kit_schedule.destroy

    respond_to do |format|
      format.html 
      format.json { head :no_content }
    end
  end
  
  private
  #def load_kit!
  #  @kit = ::Kit.find(params[:kit_id].to_i)
  #end

   def state_update(ks, trig)
    if trig == ::KitSchedule::STATE_CANCELLED
      if ks.comments.empty?
        ks.errors[:comments] << "Cannot be left empty"
        return false
      end
    end

    if trig == ::KitSchedule::STATE_ISSUED
      if ks.issued_to_user_id.nil?
        ks.errors[:issued_to_user_id] << "-- Cannot be left Blank"
        return false
      else
        user = User.find_by_id(ks.issued_to_user_id)
        if user.nil?
          ks.errors[:issued_to_user_id] << "-- User Id does not exist"
          return false
        end
      end  
    end

    if ::KitSchedule::PROCESSABLE_EVENTS.include?(trig)
      ks.send(trig)
    end
  end
end
