Feature: Display of i-flow and configuration
					View Details for a single IFlow	Single View (Two Panels)
					1. Single Iflow Viewer in Top Panel
					2. View Configuration details (for IFlow or each element) in Bottom Panel

Background: 
Given user have launched the pcc application URL 



@1 @e2e @e2eSubset @local
Scenario:  Display of IFlow and General Configuration Information for i-flow local
Given I have sucessfully logged-in 
Given I have clicked on My Projects tab
When I have clicked on first IFlow in the Table 
Then I can see the outlay window displaying iflow and its configurations


@2 @e2e @local
Scenario:  Display of IFlow Description property
Given I have sucessfully logged-in
Given I have clicked on My Projects tab
When I have clicked on an IFlow with description in the Table
Then I can see the outlay window displaying iflow and its Description

@3 @local
Scenario:  IFlow Description property in the json
When I have triggered the url for an IFlow with description
Then The iflow json should contain IFlow Description

@4 @local @e2e
Scenario: Display of Deployed date of an IFlow
Given I have sucessfully logged-in
Given I have clicked on My Projects tab
When I have clicked on an IFlow
Then I can see the outlay window displaying iflow and its Deployed date