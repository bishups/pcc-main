class AddTimingStrToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :timing_str, :string
  end
end

