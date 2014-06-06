class TeachersController < ApplicationController

  before_filter :authenticate_user!


  # GET /teachers
  # GET /teachers.json
  def index
    in_geography = (current_user.is? :any, :in_group => [:geography])
    in_training = (current_user.is? :any, :in_group => [:training])
    center_ids = (in_geography or in_training) ? current_user.accessible_center_ids : []
    # any teachers who are attached to zones, but not to the centers
    zone_ids = current_user.accessible_zone_ids
    respond_to do |format|
      if center_ids.empty? && zone_ids.empty?
        @teachers = []
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teachers, status: :unprocessable_entity }
      else
        @teachers = Teacher.joins("JOIN centers_teachers ON centers_teachers.teacher_id = teachers.id").where('centers_teachers.center_id IN (?)', center_ids).order('teachers.t_no ASC').uniq.all
        if !zone_ids.empty?
          @teachers_in_zones = Teacher.where("zone_id IN (?)", zone_ids).uniq.all
          @teachers = @teachers + (@teachers_in_zones - @teachers)
        end
        format.html # index.html.erb
        format.json { render json: @teachers }
      end
    end
  end

  # GET /teachers/1
  # GET /teachers/1.json
  def show
    @teacher = Teacher.find(params[:id])
    @teacher.current_user = current_user

    respond_to do |format|
      if @teacher.can_view?
        format.html # show.html.erb
        format.json { render json: @teacher }
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /teachers/new
  # GET /teachers/new.json
  def new
    @teacher = Teacher.new
    @teacher.current_user = current_user

    respond_to do |format|
      if @teacher.can_create? :any => true
        format.html # new.html.erb
        format.json { render json: @teacher }
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /teachers/1/edit
  def edit
    if flash[:teacher]
      @teacher = flash[:teacher]
    else
      @teacher = Teacher.find(params[:id])
      @teacher.current_user = current_user
    end
    @trigger = params[:trigger]
    @teacher.comment_category = Comment.where('model = ? AND action = ?', 'Teacher', @trigger).pluck(:text)

    respond_to do |format|
      if @teacher.can_update?
        format.html
        format.json { render json: @teacher }
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /teachers
  # POST /teachers.json
  def create
    @teacher = Teacher.new(params[:teacher])
    @teacher.current_user = current_user

    respond_to do |format|
      if @teacher.can_create?
        if @teacher.save
          format.html { redirect_to @teacher, notice: 'Teacher was successfully created.' }
          format.json { render json: @teacher, status: :created, location: @teacher }
        else
          format.html { render action: "new" }
          format.json { render json: @teacher.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /teachers/1
  # PUT /teachers/1.json
  def update
    @teacher = Teacher.find(params[:id])
    @teacher.current_user = current_user
    @trigger = params[:trigger]
    @teacher.load_comments!(params)

    respond_to do |format|
      if @teacher.can_update?
        if state_update(@teacher, @trigger) &&  @teacher.save!
          format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
          format.json { render json: @venue }
          # redirect_to [@teacher]
        else
          #flash[:teacher] = @teacher
          #format.html { redirect_to :action => :edit, :trigger => params[:trigger] }
          format.html { render :action => :edit, :trigger => params[:trigger] }
          format.json { render json: @teacher.errors, status: :unprocessable_entity }
          # flash[:teacher] = @teacher
          # redirect_to :action => :edit, :trigger => params[:trigger]
        end
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /teachers/1
  # DELETE /teachers/1.json
  def destroy
    # not allowing for now
=begin
    @teacher = Teacher.find(params[:id])
    @teacher.current_user = current_user
    @teacher.destroy

    respond_to do |format|
      format.html { redirect_to teachers_url }
      format.json { head :no_content }
    end
=end
  end

  private

  def state_update(ts, trig)
    if ::Teacher::PROCESSABLE_EVENTS.include?(@trigger)
      ts.send(trig)
    end
  end



end
