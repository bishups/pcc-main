class AddAdditionalTeacherTypes < ActiveRecord::Migration
  def change
    add_column :program_types, :minimum_no_of_organizing_teacher, :integer, :default => -1
    add_column :program_types, :minimum_no_of_hall_teacher, :integer, :default => -1
    add_column :program_types, :minimum_no_of_initiation_teacher, :integer, :default => -1
    create_table :program_types_organizing_teachers do |t|
      t.belongs_to :program_type
      t.belongs_to :teacher
    end
    create_table :program_types_hall_teachers do |t|
      t.belongs_to :program_type
      t.belongs_to :teacher
    end
    create_table :program_types_initiation_teachers do |t|
      t.belongs_to :program_type
      t.belongs_to :teacher
    end
  end
end