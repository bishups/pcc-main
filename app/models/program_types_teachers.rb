# == Schema Information
#
# Table name: program_types_teachers
#
#  id              :integer          not null, primary key
#  program_type_id :integer
#  teacher_id      :integer
#

class ProgramTypesTeachers < ActiveRecord::Base
  # attr_accessible :title, :body
end
