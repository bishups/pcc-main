# == Schema Information
#
# Table name: centers_kits
#
#  id        :integer          not null, primary key
#  center_id :integer
#  kit_id    :integer
#

class CentersKits < ActiveRecord::Base
  # attr_accessible :title, :body
end
