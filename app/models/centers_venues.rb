# == Schema Information
#
# Table name: centers_venues
#
#  id        :integer          not null, primary key
#  center_id :integer
#  venue_id  :integer
#

class CentersVenues < ActiveRecord::Base
  # attr_accessible :title, :body
end
