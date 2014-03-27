class EditVenue < ActiveRecord::Migration
  def up
    add_column :venues, :payment_contact_name, :string
    add_column :venues, :payment_contact_address, :string
    add_column :venues, :payment_contact_mobile, :string
    add_column :venues, :per_day_price, :integer
  end

  def down
    remove_column :venues, :payment_contact_name
    remove_column :venues, :payment_contact_address
    remove_column :venues, :payment_contact_mobile
    remove_column :venues, :per_day_price
  end
end
