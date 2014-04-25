class AddLastTransitionToAll < ActiveRecord::Migration
  def change
    add_column :programs, :last_update, :string
    add_column :teachers, :last_update, :string
    add_column :teacher_schedules, :last_update, :string
    add_column :venues, :last_update, :string
    add_column :venue_schedules, :last_update, :string
    add_column :kits, :last_update, :string
    add_column :kit_schedules, :last_update, :string

    add_column :teachers, :last_updated_by_user_id, :integer
    add_column :venues, :last_updated_by_user_id, :integer
    add_column :kits, :last_updated_by_user_id, :integer
  end
end

