Feature: Kit Management, Given the user logged in as user who can coordinate Kits, user should be able to manage Kits. 


Background: 
Given user have launched the pcc application URL and logged in as user who can coordinates Kits


#Role Check

@1
Scenario:  Check if all necessary actions are there to Manage Kits
Then the user should be able to View, Create, Update and Delete Kits 

#CRUD Operations

@2
Scenario:  Display of all the Kits
When the user clicks on option to view all Kits
Then the user should be shown all the Kits


@3
Scenario:  Adding of a Kit
When the user clicks on option to create a Kit
When the user enters details of Kit and does Save Action
Then a new Kit should be created

@4
Scenario: Update of a Kit
When the user clicks on option to edit a Kit
When the user edits details of Kit and does Save Action
Then Kit details should be updated


@5
Scenario: Deletion a Kit
When the user clicks on option to delete a Kit
When the user selects a Kit to Delete, and confirms the action
Then Kit should be deleted