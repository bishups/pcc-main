class ActivityLogsController < ApplicationController
  # GET /activity_logs
  # GET /activity_logs.json
  def index
    @activity_logs = ActivityLog.find_by_user(current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @activity_logs }
    end
  end

  # GET /activity_logs/1
  # GET /activity_logs/1.json
  def show
    @activity_log = ActivityLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @activity_log }
    end
  end

  # GET /activity_logs/new
  # GET /activity_logs/new.json
  def new
    @activity_log = ActivityLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @activity_log }
    end
  end

  # GET /activity_logs/1/edit
  def edit
    @activity_log = ActivityLog.find(params[:id])
  end

  # POST /activity_logs
  # POST /activity_logs.json
  def create
    @activity_log = ActivityLog.new(params[:activity_log])

    respond_to do |format|
      if @activity_log.save
        format.html { redirect_to @activity_log, notice: 'Activity log was successfully created.' }
        format.json { render json: @activity_log, status: :created, location: @activity_log }
      else
        format.html { render action: "new" }
        format.json { render json: @activity_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /activity_logs/1
  # PUT /activity_logs/1.json
  def update
    @activity_log = ActivityLog.find(params[:id])

    respond_to do |format|
      if @activity_log.update_attributes(params[:activity_log])
        format.html { redirect_to @activity_log, notice: 'Activity log was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @activity_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activity_logs/1
  # DELETE /activity_logs/1.json
  def destroy
    @activity_log = ActivityLog.find(params[:id])
    @activity_log.destroy

    respond_to do |format|
      format.html { redirect_to activity_logs_url }
      format.json { head :no_content }
    end
  end
end
