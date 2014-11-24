class AddProgramLocationTimings < ActiveRecord::Migration
  def change
    add_column :program_types, :session_duration, :integer
    add_column :venue_schedules, :payment_amount, :integer
    remove_column :venue_schedules, :per_day_price
    remove_column :teacher_schedules, :program_type_id
    add_column :teachers, :part_time_co_teacher, :boolean, :default => false
    add_column :programs, :announced_locality, :string
    add_column :programs, :announced_timing, :string
  end
end
