class AddContactPhoneEmailToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :contact_phone, :string
    add_column :programs, :contact_email, :string
  end
end
