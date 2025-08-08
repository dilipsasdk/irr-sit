#!/bin/bash

# A script that can be used for exporting data trees from a scratch org.
# They can then be imported into a different org as mock data.
#
# You need to manually create the lookup relationships in the files. See the existing data files for examples.

orgName="FCS2020Salesforce"

sfdx force:data:tree:export -q "SELECT Booking_Reference__c, Is_Cancelled__c, TEDS_Identifier__c, Type__c, (SELECT Baggage_Quantity__c, Booking_Class__c, Check_In_Status__c, Fare_Basis__c, Flight__c, Identifier__c, Is_Boarded__c, Seat__c, Service_Class__c, Special_Service_Requests__c, Ticket_Number__c, Ticket_Type__c FROM Segments__r), (SELECT Email__c, EuroBonus_Number__c, First_Name__c, Identifier__c, Last_Name__c, Name, Phone__c FROM Passengers__r) FROM Booking__c" -u $orgName --plan
sfdx force:data:tree:export -q "SELECT Arrival_Airport__c, Departure_Airport__c, Scheduled_Arrival_Time__c, Scheduled_Departure_Time__c, TEDS_Identifier__c FROM Flight__c" -u $orgName
sfdx force:data:tree:export -q "SELECT Country_of_Purchase__c, Note__c, PNR__c, Refund_Macro__c, Ticket_Numbers__c FROM Refund_Request__c" -u $orgName
sfdx force:data:tree:export -q "SELECT Team__c, Department__c, Refund_Request__c FROM Case" -u $orgName --plan
# sfdx force:data:tree:export -q "SELECT Name FROM CaseToBooking__c" -u $orgName

# To import:
# sfdx force:data:tree:import -u $orgName -p $dataPlan

