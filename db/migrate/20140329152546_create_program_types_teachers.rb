class CreateProgramTypesTeachers < ActiveRecord::Migration
  def change
    create_table :program_types_teachers do |t|
      t.belongs_to :program_type
      t.belongs_to :teacher
    end
  end
end
