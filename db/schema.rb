# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140112175234) do

  create_table "centers", :force => true do |t|
    t.string   "name"
    t.integer  "sector_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "centers", ["sector_id"], :name => "index_centers_on_sector_id"

  create_table "enquiries", :force => true do |t|
    t.string   "topic"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.text     "description"
    t.string   "state"
    t.string   "external_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "kit_item_mappings", :force => true do |t|
    t.integer  "kit_id"
    t.integer  "kit_item_id"
    t.integer  "count"
    t.string   "condition"
    t.text     "comments"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "kit_items", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "kit_item_type"
    t.string   "capacity"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "kit_schedules", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.string   "state"
    t.integer  "issued_to_person_id"
    t.integer  "blocked_by_person_id"
    t.integer  "assigned_to_program_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "kits", :force => true do |t|
    t.string   "state"
    t.integer  "max_participant_number"
    t.integer  "filling_person_id"
    t.integer  "center_id"
    t.integer  "guardian_id"
    t.string   "condition"
    t.text     "condition_comments"
    t.text     "general_comments"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 5
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles_users", :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id", :unique => true
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id", :unique => true

  create_table "sectors", :force => true do |t|
    t.string   "name"
    t.integer  "zone_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sectors", ["zone_id"], :name => "index_sectors_on_zone_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "email",                                  :default => "", :null => false
    t.string   "encrypted_password",                     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "crm_user_id"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "address",                :limit => 3000
    t.string   "phone"
    t.string   "mobile"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "venue_schedules", :force => true do |t|
    t.integer  "venue_id"
    t.integer  "reserving_user_id"
    t.string   "slot"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "venues", :force => true do |t|
    t.integer  "center_id"
    t.integer  "zone_id"
    t.string   "name"
    t.text     "description"
    t.text     "address"
    t.string   "pin_code"
    t.string   "capacity"
    t.integer  "seats"
    t.string   "state"
    t.string   "contact_name"
    t.string   "contact_email"
    t.string   "contact_phone"
    t.string   "contact_mobile"
    t.text     "contact_address"
    t.boolean  "commercial"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "versions", :force => true do |t|
    t.string   "item_type",      :null => false
    t.integer  "item_id",        :null => false
    t.string   "event",          :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "zones", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
