class KitSchedulesController < ApplicationController
  # GET /kit_schedules
  # GET /kit_schedules.json
  before_filter :authenticate_user!
  before_filter :load_kit!
  
  def index
    @kit_schedules = @kit.kit_schedules.where(['start_date > ?', DateTime.now])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @kit_schedules }
    end
  end

  # GET /kit_schedules/1
  # GET /kit_schedules/1.json
  def show
    @kit_schedule = @kit.kit_schedules.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @kit_schedule }
    end
  end

  # GET /kit_schedules/new
  # GET /kit_schedules/new.json
  def new
    @kit_schedule = @kit.kit_schedules.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @kit_schedule }
    end
  end

  # GET /kit_schedules/1/edit
  def edit
    @kit_schedule = @kit.kit_schedules.find(params[:id])
  end

  # POST /kit_schedules
  # POST /kit_schedules.json
  def create
    @kit_schedule = @kit.kit_schedules.new(params[:kit_schedule])


    respond_to do |format|
      if @kit_schedule.save
        format.html { redirect_to [@kit, @kit_schedule], notice: 'Kit schedule was successfully created.' }
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
    @kit_schedule = @kit.kit_schedules.find(params[:id])

    respond_to do |format|
      if @kit_schedule.update_attributes(params[:kit_schedule])
        format.html { redirect_to @kit_schedule, notice: 'Kit schedule was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @kit_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kit_schedules/1
  # DELETE /kit_schedules/1.json
  def destroy
    @kit_schedule = @kit.kit_schedules.find(params[:id])
    @kit_schedule.destroy

    respond_to do |format|
      format.html { redirect_to kit_schedules_url }
      format.json { head :no_content }
    end
  end
  
  private
  def load_kit!
    @kit = ::Kit.find(params[:kit_id].to_i)
  end
end
