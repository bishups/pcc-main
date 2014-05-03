class NotificationLogsController < ApplicationController
  # GET /notification_logs
  # GET /notification_logs.json
  def index
    @notification_logs = NotificationLog.find_by_user(current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notification_logs }
    end
  end

  # GET /notification_logs/1
  # GET /notification_logs/1.json
  def show
    @notification_log = NotificationLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notification_log }
    end
  end

  # GET /notification_logs/new
  # GET /notification_logs/new.json
  def new
    @notification_log = NotificationLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @notification_log }
    end
  end

  # GET /notification_logs/1/edit
  def edit
    @notification_log = NotificationLog.find(params[:id])
  end

  # POST /notification_logs
  # POST /notification_logs.json
  def create
    @notification_log = NotificationLog.new(params[:notification_log])

    respond_to do |format|
      if @notification_log.save
        format.html { redirect_to @notification_log, notice: 'Notification log was successfully created.' }
        format.json { render json: @notification_log, status: :created, location: @notification_log }
      else
        format.html { render action: "new" }
        format.json { render json: @notification_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notification_logs/1
  # PUT /notification_logs/1.json
  def update
    @notification_log = NotificationLog.find(params[:id])

    respond_to do |format|
      if @notification_log.update_attributes(params[:notification_log])
        format.html { redirect_to @notification_log, notice: 'Notification log was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @notification_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_logs/1
  # DELETE /notification_logs/1.json
  def destroy
    @notification_log = NotificationLog.find(params[:id])
    @notification_log.destroy

    respond_to do |format|
      format.html { redirect_to notification_logs_url }
      format.json { head :no_content }
    end
  end
end
