at_exit do
  testInit = TestInit.new
  if($mode == "cloud") 
    testInit.deleteDesignTimeContent
    puts "Deleting the design time content"
  end
  if($mode == "local" and $exec_env !='dev')
    testInit.disableMockImpl
    puts "Disabling Mock impl"
  end
end

AfterStep('@local') do
  if($browser == 'ie')
    sleep(2)
  end
end