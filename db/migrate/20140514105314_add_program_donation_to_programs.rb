class AddProgramDonationToPrograms < ActiveRecord::Migration
  def change
    remove_column :programs, :program_type_id
    add_column :programs, :program_donation_id, :integer
  end
end

