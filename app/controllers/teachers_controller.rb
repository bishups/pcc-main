class TeachersController < ApplicationController

  before_filter :authenticate_user!


  # GET /teachers
  # GET /teachers.json
  def index
    center_ids, zone_ids, @teachers = teachers_attached()
    @searchable_teachers = searchable_teachers()
    respond_to do |format|
      if center_ids.empty? && zone_ids.empty?
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teachers, status: :unprocessable_entity }
      else
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
      if @teacher.can_create?
        format.html # new.html.erb
        format.json { render json: @teacher }
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /teacher/comments
  # GET /teacher/comments.json
  def comments
    @teacher = Teacher.find(params[:id].to_i)
    @teacher.current_user = current_user

    respond_to do |format|
      if @teacher.can_create_schedule?
        format.html { render action: "additional_comment" }
        format.json { render json: @teacher_schedule}
      else
        format.html { redirect_to teacher_teacher_schedules_path(@teacher), :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher_schedule.errors, status: :unprocessable_entity }
      end
    end

  end


  # GET /teacher/search
  # GET /teacher/search.json
  def search
    @teachers = searchable_teachers()
    respond_to do |format|
      if @teachers.empty?
        format.html { redirect_to root_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teachers, status: :unprocessable_entity }
      else
        # we will hit search only if there are teachers listed for the user
        @teacher = @teachers[0]
        format.html { render action: "search" }
        format.json { render json: @teachers}
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
    # TODO - HACK - clean this up later
    return search_results if params.has_key?(:start_date) and params.has_key?(:end_date)
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
    return update_additional_comments if params.has_key?(:additional_comments)
    return search_results if params.has_key?(:start_date) and params.has_key?(:end_date)

    @teacher = Teacher.find(params[:id])
    @teacher.current_user = current_user

    @trigger = params[:trigger]
    @teacher.load_comments!(params)

    respond_to do |format|
      if @teacher.can_update?
        if state_update(@teacher, @trigger) &&  @teacher.save!
          format.html { redirect_to @teacher, notice: 'Teacher was successfully updated.' }
          format.json { render json: @teacher }
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


  # PUT /teachers/1
  # PUT /teachers/1.json
  def update_additional_comments
    @teacher = Teacher.find(params[:id])
    @teacher.current_user = current_user
    @teacher.additional_comments = params[:additional_comments]

    respond_to do |format|
      if @teacher.can_create_schedule?
        if @teacher.save!
          format.html { redirect_to teacher_teacher_schedules_path(@teacher), notice: 'Teacher was successfully updated.' }
          format.json { render json: @teacher }
        else
          format.html { render :action => :comments, :trigger => params[:trigger] }
          format.json { render json: @teacher.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to teachers_path, :alert => "[ ACCESS DENIED ] Cannot perform the requested action. Please contact your coordinator for access." }
        format.json { render json: @teacher.errors, status: :unprocessable_entity }
      end
    end
  end

  def search_results
    # HACK - fix this - should not create temporary in-memory object
    @teacher = Teacher.new
    @teacher.errors.add(:teachers, " cannot be left blank") if params[:teacher_ids].blank?
    @teacher.errors.add(:start_date, " cannot be left blank") if params[:start_date].blank?
    @teacher.errors.add(:end_date, " cannot be left blank") if params[:end_date].blank?
    if @teacher.errors.empty?
      @start_date = DateTime.strptime(params[:start_date], '%d %B %Y (%A)').to_date
      @end_date = DateTime.strptime(params[:end_date], '%d %B %Y (%A)').to_date
      @teacher.errors.add(:start_date, " cannot exceed end date") if @end_date < @start_date
    end

    @teachers = searchable_teachers()
    respond_to do |format|
      if @teacher.errors.empty?
        teacher_ids = params[:teacher_ids].map {|s| s.to_i }
        teacher_schedules = TeacherSchedule.where("teacher_id IN (?) AND ((start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?) OR  (start_date <= ? AND end_date >= ?)) AND state IN (?)",
                                                  teacher_ids, @start_date, @end_date, @start_date, @end_date, @start_date, @end_date, (::ProgramTeacherSchedule::CONNECTED_STATES + ::TeacherSchedule::RESERVED_STATES + [::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED])).all
        # add dummy entry for start and end date
        @teacher_schedules = [[' ', ' ', [@start_date.year, @start_date.month-1, @start_date.day, 0, 0, 0], [@start_date.year, @start_date.month-1, @start_date.day, 0, 0, 0],"white"],
                              [' ', ' ', [@end_date.year, @end_date.month-1, @end_date.day, 23, 59, 59], [@end_date.year, @end_date.month-1, @end_date.day, 23, 59, 59],"white"]
                             ]
        # add teacher schedules found
        teachers_added = []
        teacher_schedules.each { |ts|
          if ts.program.blank?
            st = [ts.start_date.year, ts.start_date.month-1, ts.start_date.day, 0, 0, 0]
            et = [ts.end_date.year, ts.end_date.month-1, ts.end_date.day, 23, 59, 59]
            if ts.state == ::TeacherSchedule::STATE_RESERVED
              color = "red"
            elsif ts.state == ::TeacherSchedule::STATE_BREAK
              color = "blue"
            else
              color = "green"
            end
            comments = ts.comments.blank? ? "" : "-#{ts.comments}"
            desc = "#{ts.state}#{comments} (*#{ts.id})"
          else
            st = [ts.program.start_date.year, ts.program.start_date.month-1, ts.program.start_date.day,
                  ts.program.start_date.hour, ts.program.start_date.min, ts.program.start_date.sec]
            et = [ts.program.end_date.year, ts.program.end_date.month-1, ts.program.end_date.day,
                  ts.program.end_date.hour, ts.program.end_date.min, ts.program.end_date.sec]
            color = ts.state == ::ProgramTeacherSchedule::STATE_BLOCK_REQUESTED ? "yellow" : "green"
            desc = "#{ts.program.program_donation.program_type.name}-#{ts.program.center.name} (##{ts.id})"
          end
          schedule = ["#{ts.teacher.user.fullname} (##{ts.teacher.id})", desc, st, et, color]
          teachers_added << ts.teacher unless teachers_added.include?(ts.teacher)
          @teacher_schedules << schedule
        }

        # add dummy entries for teachers for whom no schedule was found
        @teachers.each { |teacher|
          next if teachers_added.include?(teacher)
          @teacher_schedules << ["#{ts.teacher.user.fullname} (##{ts.teacher.id})", ' ',
                                 [@start_date.year, @start_date.month-1, @start_date.day, 0, 0, 0],
                                 [@start_date.year, @start_date.month-1, @start_date.day, 0, 0, 0],
                                 "white"]

        }

        # sort the array based on teacher_name
        @teacher_schedules.sort_by!{ |v| v[0]}

        format.html { render template: "teachers/search_results", :locals => {:teacher_schedules => @teacher_schedules}}# search_results.html.erb
        format.json { render json: @teachers }
      else
        format.html { render :action => :search}
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

  def teachers_attached
    in_geography = (current_user.is? :any, :in_group => [:geography])
    in_training = (current_user.is? :any, :in_group => [:training])
    center_ids = (in_geography or in_training) ? current_user.accessible_center_ids : []
    zone_ids = (in_geography or in_training) ? current_user.accessible_zone_ids : []
    teachers = []
    if not center_ids.empty?
      teachers = Teacher.joins("JOIN centers_teachers ON centers_teachers.teacher_id = teachers.id").where('centers_teachers.center_id IN (?)', center_ids).order('teachers.t_no ASC').uniq.all
    end
    if not zone_ids.empty?
      teachers += Teacher.joins("JOIN zones_teachers on teachers.id = zones_teachers.teacher_id").where("zones_teachers.zone_id IN (?)", zone_ids).uniq.all
      teachers += Teacher.joins("JOIN secondary_zones_teachers on teachers.id = secondary_zones_teachers.teacher_id").where("secondary_zones_teachers.zone_id IN (?)", zone_ids).uniq.all
    end
    return center_ids, zone_ids, (teachers.uniq)
  end

  def searchable_teachers
    cids, zids, attached = teachers_attached()
    searchable = []
    attached.each{ |teacher|
      next unless teacher.can_view_schedule?
      searchable << teacher
    }
    searchable
  end

  private

  def state_update(ts, trig)
    if ::Teacher::PROCESSABLE_EVENTS.include?(@trigger)
      ts.send(trig)
    end
  end



end
