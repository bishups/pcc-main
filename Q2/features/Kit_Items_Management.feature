Feature: Kit Items management, Given the user logged in as user who can coordinate Kit Items, user should be able to manage Kit Items .

Background: 
Given user have launched the pcc application URL and logged in as user who can coordinates Kit Items


#Role Check

@1
Scenario:  Check if all necessary actions are there to Manage Kit Items
Then the user should be able to View, Create, Update and Delete Kits 

#CRUD Operations

@2
Scenario:  Display of all the Kit Items
When the user clicks on option to view all Kit Items
Then the user should be shown all the Kit Items


@3
Scenario:  Adding of a Kit Item
When the user clicks on option to create a Kit Item
When the user enters details of Kit Item and does Save Action
Then a new Kit Item should be created

@4
Scenario: Update of a Kit Item
When the user clicks on option to edit a Kit Item
When the user edits details of Kit Item and does Save Action
Then Kit Item details should be updated


@5
Scenario: Deletion a Kit Item
When the user clicks on option to delete a Kit Item
When the user selects a Kit Item to Delete, and confirms the action
Then Kit Item should be deleted