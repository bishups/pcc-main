class CreateTravelTickets < ActiveRecord::Migration
  def change
    create_table :travel_tickets do |t|
      t.string :name
      t.string :attachment

      t.timestamps
    end
  end
end
