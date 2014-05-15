class CreateCentersProgramDonations < ActiveRecord::Migration
  def change
    create_table :centers_program_donations do |t|
      t.integer :center_id
      t.integer :program_donation_id
    end
  end
end
