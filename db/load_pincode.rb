# create pincodes
# workbook = RubyXL::Parser.parse("pincode.xlsx")
# sheet=workbook["Pincode"].get_table
# sheet[:table].each do |row|
#   puts  row["Pincode"]
#   puts   row["Location"]
#   debugger
#   pincode = Pincode.new(:pincode => row["Pincode"].to_i, :location_name => row["Location"] )
#   if not pincode.save
#     puts "Error in saving pincode #{pincode.errors.messages}"
#   end
#
# end

(111111 .. 999999).each do |pincode_name|
  pincode = Pincode.new(:pincode => pincode_name.to_s, :location_name => pincode_name.to_s)
  if not pincode.save
    puts "Error in saving pincode #{pincode.errors.messages}"
  end
end