
require 'capybara/cucumber'
require 'rubygems'
require 'require_relative'
require_relative '../step_definitions/TestInit.rb'
require_relative '../support/HttpClientUtil.rb'

Capybara.javascript_driver = :selenium
Capybara.default_selector = :css
#appurl = 'https://tmd1td1avttri-td1.neo.ondemand.com'
appurl = ENV['url']
$browser = ENV['browser']
$mode = ENV['mode']
nodetype = ENV['nodetype']
$exec_env='ci'

Capybara.app_host = appurl
Capybara.default_driver = :selenium
Capybara.default_wait_time = 15 #When we testing AJAX, we can set a default wait time
Capybara.ignore_hidden_elements = false

testInit = TestInit.new

if(Capybara.app_host.index("http://localhost") == 0)
  puts 'developement environment'
  $exec_env='dev'
end
#Creation of test content only in case mode is cloud..
if($mode == "cloud" and nodetype!="ccn")
  testInit.deleteDesignTimeContent
	testInit.createDesignTimeContent
	testInit.createRuntimeContent
	testInit.disableMockImpl
end

if($mode == "cloud" and nodetype=="ccn")
  testInit.deleteDesignTimeContent
  testInit.createDesignTimeContent
  testInit.disableMockImpl
end

if($mode == "local" || $exec_env =='dev')
  testInit.enableMockImpl
end

Capybara.register_driver :selenium do |app|
  if($browser == "firefox")
   Capybara::Selenium::Driver.new(app, :browser => :firefox)
  elsif($browser == "chrome")
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
	elsif($browser == "ie")
	Capybara::Selenium::Driver.new(app, :browser => :ie)
	elsif($browser == "safari")
	Capybara::Selenium::Driver.new(app, :browser => :safari)
	else
	Capybara::Selenium::Driver.new(app,:browser => :ie)
    end   
end

