require 'selenium-webdriver'

$session = Capybara::Session.new(:selenium)

$iflow = 'Config_IFLMAP'

Given(/^I have sucessfully logged\-in$/) do
    dologin
end

Given /^I have clicked on My Projects tab$/ do
  find(".sapUiUx3Shell").first(".sapUiUx3NavBar").find(".sapUiUx3NavBarItem", :text => 'My Projects').click
end

When /^I have clicked on first IFlow in the Table$/ do
	find(:css,'.sapUiTableCtrlCnt').should be_visible
	find("a[id$='lnkIFlowName-col0-row1']").click
end

Then /^I can see the outlay window displaying iflow and its configurations$/ do
  find("div[class='sapUiUx3OCOverlay sapUiUx3OverlayOverlay']")
end



#Scenario : 2 
When(/^I have clicked on an IFlow with description in the Table$/) do
    find_link($iflow).click
end

Then(/^I can see the outlay window displaying iflow and its Description$/) do
    find(".canvas")
    find("textarea[id$='iflowDescription']").should have_content('IFlow to test configuration edit')
end

# Scenario 3 
When(/^I have triggered the url for an IFlow with description$/) do
   getServerResponse('api/1.0/iflows/Config_IFLMAP')
end

Then(/^The iflow json should contain IFlow Description$/) do
    $serverResponse.body.should have_content('"description":"IFlow to test configuration edit"}')
end

# Scenario 4
When(/^I have clicked on an IFlow$/) do
	find_link($iflow).click
end

Then(/^I can see the outlay window displaying iflow and its Deployed date$/) do
	find("input[id$='iflowDeployedDate']").value.should eq '02/14/13 05:29 AM'
end