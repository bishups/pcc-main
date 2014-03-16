Feature: Venue Management, Given the user logged in as user who can coordinates Venue, user should be able to manage Venues. 


Background: 
Given user have launched the pcc application URL and logged in as user who can coordinates Venues


#Role Check

@1
Scenario:  Check if all necessary actions are there to Manage Venues
Then the user should be able to View, Create, Update and Delete Venues 

#CRUD Operations

@2
Scenario:  Display of all the Venues
When the user clicks on option to view all Venues
Then the user should be shown all the Venues


@3
Scenario:  Adding of a Venue
When the user clicks on option to create a Venue
When the user enters details of Venue and does Save Action
Then a new Venue should be created

@4
Scenario: Update of a Venue
When the user clicks on option to edit a Venue
When the user edits details of Venue and does Save Action
Then Venue details should be updated


@5
Scenario: Deletion a Venue
When the user clicks on option to delete a Venue
When the user selects a Venue to Delete, and confirms the action
Then Venue should be deleted