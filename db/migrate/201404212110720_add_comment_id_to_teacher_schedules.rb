class AddCommentIdToTeacherSchedules < ActiveRecord::Migration
  def change
    add_column :teacher_schedules, :comment_id, :integer
    add_column :teacher_schedules, :comments, :text
    add_column :teacher_schedules, :teacher_comments, :text
    add_column :teacher_schedules, :feedback, :text
  end
end

