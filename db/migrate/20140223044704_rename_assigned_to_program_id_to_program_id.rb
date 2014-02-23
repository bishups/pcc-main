class RenameAssignedToProgramIdToProgramId < ActiveRecord::Migration
  def up
        rename_column :kit_schedules , :assigned_to_program_id , :program_id

  end

  def down
  end
end
