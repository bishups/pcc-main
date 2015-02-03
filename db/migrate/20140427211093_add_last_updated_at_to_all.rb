class AddLastUpdatedAtToAll < ActiveRecord::Migration
  def change
    add_column :programs, :last_updated_at, :datetime
    add_column :teachers, :last_updated_at, :datetime
    add_column :teacher_schedules, :last_updated_at, :datetime
    add_column :venues, :last_updated_at, :datetime
    add_column :venue_schedules, :last_updated_at, :datetime
    add_column :kits, :last_updated_at, :datetime
    add_column :kit_schedules, :last_updated_at, :datetime
  end
end

