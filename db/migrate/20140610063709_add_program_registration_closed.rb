class AddProgramRegistrationClosed < ActiveRecord::Migration
  def change
    add_column :program_types, :registration_close_timeout, :integer
    add_column :programs, :registration_closed, :boolean, :default => false
    add_column :programs, :capacity, :integer
    add_column :program_types, :minimum_no_of_co_teacher, :integer
    add_column :teacher_schedules, :co_teacher, :boolean, :default => false
    add_column :teachers, :full_time, :boolean, :default => false
  end
end
