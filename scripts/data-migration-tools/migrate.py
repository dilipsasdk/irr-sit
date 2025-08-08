import pandas as pd
import pyclip
import random
import os

PATH = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = PATH+'/dataToImport/'
EXPORT_PATH = PATH+'/exportedData/'
# TODO: autofix pnr masking
# EU261-specific filtering: 
# WHERE ID IN (SELECT CASE__C FROM CASETOBOOKING__C WHERE BOOKING__R.TYPE__C = 'ONEWAY')
CASE_QUERY = "Select CaseNumber, Claim_Expenses__c, Department__c, FCS_CaseResolution__c, FCS_CaseType__c, FCS_Case_Reason__c, FCS_EBLevel__c, Id, LIA_Claim__c, Subject, Priority, Status, Type FROM Case WHERE Status = 'Closed' AND Type = 'Claim' AND Customer_Claim_Type__c = 'Flight delay' LIMIT 20"
CLAIMS_QUERY = "Select Case__c, Type_of_Customer__c, Liability_PNR__c, Country__c, Customer_Claim_Category__c, Customer_Claim_Type__c, Customer_Reason_for_EU261_Claim__c, Delay_Length__c, Flight_Date__c, Flight_Number__c, Id, Name, Contact_Last_Name__c FROM LIA_Claim__c WHERE Case__c IN " # caseIds
CASETOBOOKINGS_QUERY = "Select Booking__c, Case__c, Id, Name FROM CaseToBooking__c WHERE Case__c IN " # caseIds
BOOKINGS_QUERY = "Select Booking_Reference__c, Id, Name, TEDS_Identifier__c, Type__c FROM Booking__c WHERE Id IN " # bookingIds
PASSENGERS_QUERY = "Select Booking__c, Id, Identifier__c, First_Name__c, Last_Name__c FROM Passenger__c WHERE Booking__c IN " # bookingIds
SEGMENTS_QUERY = "Select Baggage_Quantity__c, Booking_Class__c, Booking__c, Check_In_Status__c, Fare_Basis__c, Flight__c, Id, Identifier__c, Seat__c, Trip_Type__c, Ticket_Number__c FROM Segment__c WHERE Booking__c IN " # bookingIds
FLIGHTS_QUERY = "Select Actual_Arrival_Time__c, Actual_Departure_Time__c, Arrival_Airport__c, Arrival_Delayed_Minutes__c, Arrival_Status__c, Departure_Airport__c, Departure_Delayed_Minutes__c, Departure_Terminal__c, Departure_Status__c, Id, Estimated_Arrival_Time__c, Estimated_Departure_Time__c, Name, Operating_Carrier__c, Scheduled_Arrival_Time__c, Scheduled_Departure_Time_Local__c, Scheduled_Departure_Time__c, TEDS_Identifier__c FROM Flight__c WHERE Id IN " # flightIds
FLIGHTIRREGULARITIES_QUERY = "Select Code__c, Description__c, Duration_minutes__c, Flight__c, Id, Name, Reason__c, Type__c FROM FlightIrregularities__c WHERE Flight__c IN " # flightIds
CONTENTDOCUMENTLINKS_QUERY = "Select Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN " # claimIds
CUSTOMER_QUERY = "Select Id, Email__c, Claim__c, First_Name__c, Last_Name__c FROM Customer__c WHERE Claim__c IN " # claimIds

randTEDSId = ''.join([str(random.randint(0,9)) for _ in range(8)])
TEMPID_SCRIPT = """
Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Claim').getRecordTypeId();
Id caseOwnerId = GroupsSelector.newInstance().selectQueuesByDepartment(new Set<String>{ 'Customer Claim' })[0].Id;
Booking__c b = new Booking__c(TEDS_Identifier__c = '"""+randTEDSId+"""'); // f-string ruins the "new Set"
Flight__c f = new Flight__c(TEDS_Identifier__c = '"""+randTEDSId+"""');
LIA_Claim__c c = new LIA_Claim__c();
insert b; // List insert creates python issues
insert f;
insert c;
System.debug('Temporary Booking__c.Id: ');
System.debug(b.Id);
System.debug('Temporary Flight__c.Id: ');
System.debug(f.Id);
System.debug('Temporary LIA_Claim__c.Id: ');
System.debug(c.Id);
System.debug('RecordTypeId: ');
System.debug(recordTypeId);
System.debug('CaseOwnerId: ');
System.debug(caseOwnerId);
"""

CONNECT_SCRIPT = """
Set<String> caseIds = new Set<String>{REPLACE_ME_WITH_CASE_IDS};
Set<String> bookingIds = new Set<String>{REPLACE_ME_WITH_BOOKING_IDS};
Set<String> flightIds = new Set<String>{REPLACE_ME_WITH_FLIGHT_IDS};
List<Case> cases = [SELECT Id, SuppliedName, SuppliedCompany FROM Case WHERE SuppliedName IN :caseIds];
List<LIA_Claim__c> claims = [SELECT Id, Name, Contact_Last_Name__c FROM LIA_Claim__c WHERE Name IN :caseIds];
// List<ContentDocumentLink> ContentDocumentLinks = [SELECT Name FROM ContentDocumentLink WHERE Name IN :caseIds];
List<Booking__c> Bookings = [SELECT Id, Name FROM Booking__c WHERE Name IN :bookingIds];
List<Passenger__c> Passengers = [SELECT  Id, Name, Account__c, Booking__c, Email__c, EuroBonus_Number__c, First_Name__c, Identifier__c, Last_Name__c, Phone__c FROM Passenger__c WHERE Name IN :bookingIds];
List<Segment__c> Segments = [SELECT Id, Name, Baggage_Quantity__c, Booking__c, Booking_Class__c, Check_In_Status__c, Fare_Basis__c, Flight__c, Identifier__c, Is_Boarded__c, Seat__c, Segment_Status__c, Segment_Status_Code__c, Service_Class__c, Special_Service_Requests__c, Ticket_Number__c, Ticket_Type__c, Trip_Type__c FROM Segment__c WHERE Name IN :bookingIds];
List<Flight__c> Flights = [SELECT Id, Name FROM Flight__c WHERE Name IN :flightIds];
List<FlightIrregularities__c> FlightIrregularities = [SELECT Id, Name, Code__c, Flight__c, Reason__c, Duration_minutes__c, Type__c, Description__c FROM FlightIrregularities__c WHERE Name IN :flightIds];
List<CaseToBooking__c> CaseToBookings = new List<CaseToBooking__c>();

List<SObject> toDelete = new List<SObject>();
List<SObject> toUpdate = new List<SObject>();
// For some reason we have to divide this, SF complains of 10+ chunks (which there should not be)
List<Segment__c> segmentsToInsert = new List<Segment__c>();
List<FlightIrregularities__c> irregularitiesToInsert = new List<FlightIrregularities__c>();
List<Passenger__c> passengersToInsert = new List<Passenger__c>();
List<Customer__c> customersToInsert = new List<Customer__c>();
List<Segment__c> segmentsToDelete = new List<Segment__c>();
List<FlightIrregularities__c> irregularitiesToDelete = new List<FlightIrregularities__c>();
List<Passenger__c> passengersToDelete = new List<Passenger__c>();
List<Customer__c> customersToDelete = new List<Customer__c>();

Map<String, Id> oldCaseIdToNewCaseId = new Map<String, Id>();
Map<String, Id> oldBookingIdToNewBookingId = new Map<String, Id>();
Map<String, Id> oldFlightIdToNewFlightId = new Map<String, Id>();
Map<String, Id> oldClaimIdToNewClaimId = new Map<String, Id>();
Map<Id, Id> caseIdToClaimId = new Map<Id, Id>();
for (Booking__c b : Bookings) {
    oldBookingIdToNewBookingId.put(b.Name, b.Id);
}
for (Case c : cases) {
    oldCaseIdToNewCaseId.put(c.SuppliedName, c.Id);
    // Create CaseToBookings
    CaseToBooking__c ctb = new CaseToBooking__c(
    Booking__c = oldBookingIdToNewBookingId.get(c.SuppliedCompany),
    Case__c = c.Id
    );
    CaseToBookings.add(ctb);
}
for (Flight__c f : Flights) {
    oldFlightIdToNewFlightId.put(f.Name, f.Id);
}

// Connect the claim to the case
Set<String> claimIdsSpecial = new Set<String>();
for (LIA_Claim__c cl : claims) {
    oldClaimIdToNewClaimId.put(cl.Contact_Last_Name__c.toLowerCase(), cl.Id); // Can mean errors
    Id caseId = oldCaseIdToNewCaseId.get(cl.Name);
    cl.Case__c = caseId;
    caseIdToClaimId.put(caseId, cl.Id);
    toUpdate.add(cl);
    claimIdsSpecial.add(cl.Contact_Last_Name__c + '@gmail.com');
}

List<Customer__c> customers = [SELECT Id, Email__c, Claim__c, First_Name__c, Last_Name__c FROM Customer__c WHERE Email__c IN :claimIdsSpecial];

// Connect the case to the claim
for (Case c : cases) {
    c.LIA_Claim__c = caseIdToClaimId.get(c.Id);
    toUpdate.add(c);
}

// Connect the passengers to the bookings
for (Passenger__c p : passengers) {
    Passenger__c newPassenger = p.clone(False,False,False,False);
    newPassenger.Booking__c = oldBookingIdToNewBookingId.get(p.Name);
    passengersToDelete.add(p);
    passengersToInsert.add(newPassenger);
}

for (Customer__c cu : customers) {
    Customer__c newCustomer = cu.clone(False,False,False,False);
    String oldClaimId = cu.Email__c.replace('@gmail.com', '');
    newCustomer.Claim__c = oldClaimIdToNewClaimId.get(oldClaimId);
    customersToDelete.add(cu);
    customersToInsert.add(newCustomer);
}

// Connect the irregularities to the flights
for (FlightIrregularities__c fi : FlightIrregularities) {
    FlightIrregularities__c newFi = fi.clone(False,False,False,False);
    newFi.Flight__c = oldFlightIdToNewFlightId.get(fi.Name);
    irregularitiesToInsert.add(newFi);
    irregularitiesToDelete.add(fi);
}

for (Segment__c s : Segments) {
    Segment__c newSegment = s.clone(False,False,False,False);
    newSegment.Booking__c = oldBookingIdToNewBookingId.get(s.Name);
    newSegment.Flight__c = oldFlightIdToNewFlightId.get(s.Ticket_Number__c);
    segmentsToDelete.add(s);
    segmentsToInsert.add(newSegment);
}

// toUpdate.addAll(ContentDocumentLinks);
insert CaseToBookings;
insert segmentsToInsert;
insert irregularitiesToInsert;
insert passengersToInsert;
insert customersToInsert;
update toUpdate;
delete segmentsToDelete;
delete irregularitiesToDelete;
delete passengersToDelete;
delete customersToDelete;
"""

CLEANUP_SCRIPT = f"""
List<Booking__c> tempBooking = [SELECT Id FROM Booking__c WHERE TEDS_Identifier__c = '{randTEDSId}'];
List<Flight__c> tempFlight = [SELECT Id FROM Flight__c WHERE TEDS_Identifier__c = '{randTEDSId}'];
delete tempBooking;
delete tempFlight;
"""

AIRPORT_SCRIPT = f"""
List<Airport__c> allAirports = [SELECT Id, Country_Code__c FROM Airport__c];
new Airports(allAirports).setEU261Applicable();
"""

lastNameToMask = {}
PNRToMask = {}
TEDSIDToMask = {}

class MetaInfo:
    def __init__(self):
        self.Cases = None
        self.Claims = None
        self.Bookings = None
        self.Passengers = None
        self.CaseToBookings = None
        self.Flights = None
        self.FlightIrregularities = None
        self.Segments = None
        self.ContentDocumentLinks = None
        self.Customers = None
        self.caseIds = ''
        self.claimIds = ''
        self.bookingIds = ''
        self.flightIds = ''

def main():
    metaInfo = MetaInfo()
    objectNames = ['Case', 'LIA_Claim__c', 'CaseToBooking__c', 'ContentDocumentLink', 'Booking__c', 'Passenger__c', 'Customer__c', 'Segment__c', 'Flight__c', 'FlightIrregularities__c'] # TODO Airports
    objectToHandleFunction = {'Case' : handleCases, 'LIA_Claim__c': handleClaims, 'Booking__c': handleBookings, 'Passenger__c': handlePassengers, 'CaseToBooking__c': handleCaseToBookings, 'Flight__c': handleFlights, 'FlightIrregularities__c': handleFlightIrregularities, 'Segment__c': handleSegments, 'ContentDocumentLink': handleContentDocumentLinks, 'Customer__c' : handleCustomers}
    objectQueries = {'Case': CASE_QUERY, 'LIA_Claim__c': CLAIMS_QUERY, 'Booking__c': BOOKINGS_QUERY, 'Passenger__c': PASSENGERS_QUERY, 'CaseToBooking__c': CASETOBOOKINGS_QUERY, 'Flight__c': FLIGHTS_QUERY, 'FlightIrregularities__c': FLIGHTIRREGULARITIES_QUERY, 'Segment__c': SEGMENTS_QUERY, 'ContentDocumentLink': CONTENTDOCUMENTLINKS_QUERY, 'Customer__c': CUSTOMER_QUERY}
    print('----- Script to aid in data migration -----')
    print('WARNING: All data in the "exportedData"-folder will be overwritten.')
    print('WARNING: Clipboard will be overwritten.')
    print('WARNING: Maxiumum amount of case records recommended: ~300 (10.000 DML operations, Salesforce CPU-time etc.).')
    input('Press anything to continue...\n')
    print('0. Clear the "dataToImport" folder.')
    input('Press anything to continue...\n')
    
    taskCount = 1
    for objectName in objectNames:
        print(f'{taskCount}. Export "{objectName}"-objects to csv using this query (Copied to clipboard): ')

        query = objectQueries.get(objectName)
        if objectName in ['LIA_Claim__c', 'CaseToBooking__c']:
            query += metaInfo.caseIds
        elif objectName in ['Booking__c', 'Passenger__c', 'Segment__c']:
            query += metaInfo.bookingIds
        elif objectName in ['Flight__c', 'FlightIrregularities__c']:
            query += metaInfo.flightIds
        elif objectName in ['ContentDocumentLink', 'Customer__c']:
            query += metaInfo.claimIds

        pyclip.copy(query)
        print(query)

        if objectName == 'Case':
            print('(Edit the "WHERE" clauses and "LIMIT" if needed)')
        
        input('Press anything to continue...\n')
        print(f'{taskCount+1}. Put the csv-file in the "dataToImport"-folder')
        input('Press anything to continue...\n')
        df = getDataFrame(objectName)
        objectToHandleFunction.get(objectName)(df, metaInfo)
        taskCount += 2
    
    print('\n----- Creating CSV-files for import -----\n')
    createCSVFiles(metaInfo, taskCount)

def clearParentheses(toClearFrom):
    return toClearFrom.replace('(', '').replace(')', '')

def createCSVFiles(metaInfo, taskCount):
    input('A couple of scripts to run are going to follow.')
    print('Press anything to continue...\n')
    promptRunScript(1, TEMPID_SCRIPT)
    tempBookingId = input('Enter the temporary Booking__c.Id: ')
    tempFlightId = input('Enter the temporary Flight__c.Id: ')
    tempClaimId = input('Enter the temporary LIA_Claim__c.Id: ')
    recordTypeId = input('Enter the RecordTypeId: ')
    caseOwnerId = input('Enter the CaseOwnerId: ')
    
    connectCasesToBookings(metaInfo) 

    # Store Ids
    metaInfo.Cases['SUPPLIEDNAME'] = metaInfo.Cases['ID']
    metaInfo.Cases['RecordTypeId'] = recordTypeId
    metaInfo.Cases['OwnerId'] = caseOwnerId
    metaInfo.Bookings['NAME'] = metaInfo.Bookings['ID']
    metaInfo.Flights['NAME'] = metaInfo.Flights['ID']

    writeToCsv(metaInfo.Cases, 'Case')

    metaInfo.Claims['NAME'] = metaInfo.Claims['CASE__C']
    metaInfo.Claims['CONTACT_LAST_NAME__C'] = metaInfo.Claims['ID']
    # metaInfo.Claims['NAME'] = metaInfo.Claims['CASE__C'] # Contact_Email__c
    writeToCsv(metaInfo.Claims, 'LIA_Claim__c')
    # writeToCsv(metaInfo.ContentDocumentLinks, 'ContentDocumentLink')
    
    writeToCsv(metaInfo.Bookings,'Booking__c')

    metaInfo.Passengers['NAME'] = metaInfo.Passengers['BOOKING__C'] 
    metaInfo.Customers['EMAIL__C'] = metaInfo.Customers['CLAIM__C'] 
    metaInfo.Customers['EMAIL__C'] = metaInfo.Customers['EMAIL__C'].apply(addGmail)
    metaInfo.Segments['NAME'] = metaInfo.Segments['BOOKING__C']
    metaInfo.Segments['TICKET_NUMBER__C'] = metaInfo.Segments['FLIGHT__C']
    metaInfo.Passengers = metaInfo.Passengers.assign(BOOKING__C=tempBookingId) 
    metaInfo.Customers = metaInfo.Customers.assign(CLAIM__C=tempClaimId) 
    metaInfo.Segments = metaInfo.Segments.assign(BOOKING__C=tempBookingId) 
    metaInfo.Segments = metaInfo.Segments.assign(FLIGHT__C=tempFlightId) 
    writeToCsv(metaInfo.Passengers,'Passenger__c')
    writeToCsv(metaInfo.Customers,'Customer__c')
    writeToCsv(metaInfo.Segments,'Segment__c')

    writeToCsv(metaInfo.Flights,'Flight__c')

    metaInfo.FlightIrregularities['NAME'] = metaInfo.FlightIrregularities['FLIGHT__C']
    metaInfo.FlightIrregularities = metaInfo.FlightIrregularities.assign(FLIGHT__C=tempFlightId) 
    writeToCsv(metaInfo.FlightIrregularities,'FlightIrregularities__c')

    print('Import all csv-files in the "exportedData" folder using Salesforce Inspector')
    input('Press anything to continue...\n')

    promptRunScript(2, CONNECT_SCRIPT.replace('REPLACE_ME_WITH_CASE_IDS', clearParentheses(metaInfo.caseIds)).replace('REPLACE_ME_WITH_BOOKING_IDS', clearParentheses(metaInfo.bookingIds)).replace('REPLACE_ME_WITH_FLIGHT_IDS', clearParentheses(metaInfo.flightIds)))
    
    print('Import all airports using the Airports.csv file in "scripts\create-org-mock-data\Airport__c.csv"')
    input('Press anything to continue...\n')
    
    promptRunScript(4, AIRPORT_SCRIPT)

    print('Migrate complete!')

def connectCasesToBookings(metaInfo):
    metaInfo.CaseToBookings
    newDf = metaInfo.CaseToBookings[['BOOKING__C', 'CASE__C']].copy()
    newDf = newDf.rename(columns = {'CASE__C' : 'ID'}) # For merge
    metaInfo.Cases = metaInfo.Cases.merge(newDf, how='left')
    metaInfo.Cases = metaInfo.Cases.rename(columns = {'BOOKING__C' : 'SUPPLIEDCOMPANY'}) # Store in worthless column

def promptRunScript(no, script):
    pyclip.copy(script)
    print(f'----- SCRIPT {no} START -----')
    print(script)
    print(f'------ SCRIPT {no} END ------')
    print('Paste and run the script above in an "execute-anonymous"-window (Copied to clipboard)')
    if (no==2):
        print('DISCLAIMER: If you have imported a lot of objects you might have to add the code to a function of a class and run it that way.')
    input('Press anything to continue...\n')

def constructDict(deconstructedDict):
    oldCaseIdToNewCaseId = {}
    for pair in deconstructedDict.split(';'):
        splitPair = pair.split(',')
        try:
            oldCaseIdToNewCaseId[splitPair[0]] = splitPair[1]
        except:
            break
    return oldCaseIdToNewCaseId

def writeToCsv(df, name):
    df = df.drop(['ID'], axis=1)
    if name == 'Case':
        df = df.drop(['CASENUMBER', 'LIA_CLAIM__C'], axis=1)
        # df = df.assign(STATUS='new')
    if name == 'LIA_Claim__c':
        df = df.drop(['CASE__C'], axis=1)
        df['LIABILITY_PNR__C'] = df['LIABILITY_PNR__C'].apply(maskBookingReference)
    if name == 'Booking__c': # Create fake PNRs (GDPR)
        df['TEDS_IDENTIFIER__C'] = df['TEDS_IDENTIFIER__C'].apply(randomizeTEDSIdentifier)
        df['BOOKING_REFERENCE__C'] = df['BOOKING_REFERENCE__C'].apply(maskBookingReference)
    if name == 'Flight__c':
        df['TEDS_IDENTIFIER__C'] = df['TEDS_IDENTIFIER__C'].apply(randomizeTEDSIdentifier)
    if name in ['Passenger__c', 'Customer__c']:
        df['LAST_NAME__C'] = df['LAST_NAME__C'].apply(maskLastName)
        df['FIRST_NAME__C'] = df['FIRST_NAME__C'].apply(maskLastName)

    fileName = f'prepared{name}s.csv'
    df.to_csv(f'{EXPORT_PATH}/{fileName}', index=False)
    print(f'{fileName} created.')

# Randomizes the "airport"-part of the TEDSIdentifier (to avoid conflicts)
def randomizeTEDSIdentifier(x):
    x = str(x)
    existingMask = TEDSIDToMask.get(x)
    if (existingMask != None):
        return existingMask
    
    mask = x[:len(x) - 7]
    mask += ''.join([str(random.randint(0,9)) for _ in range(3)]) + '-' + ''.join([str(random.randint(0,9)) for _ in range(3)])
    if (mask in TEDSIDToMask.values()):
        return randomizeTEDSIdentifier(x) # Run until unique
    TEDSIDToMask[x] = mask
    return mask

def maskBookingReference(x):
    x = str(x)
    existingMask = PNRToMask.get(x)
    if (existingMask != None):
        return existingMask
    
    mask = x[:len(x) - 6]
    mask += ''.join([str(random.randint(0,9)) for _ in range(6)])
    if (mask in PNRToMask.values()):
        return maskBookingReference(x) # Run until unique
    PNRToMask[x] = mask
    return mask

def maskLastName(x):
    x = str(x)
    existingMask = lastNameToMask.get(x.lower())
    if (existingMask != None):
        return existingMask

    mask = ''.join([str(random.randint(0,9)) for _ in range(8)])
    if (mask in lastNameToMask.values()):
        return maskLastName(x) # Run until unique
        
    lastNameToMask[x.lower()] = mask
    return mask

def addGmail(x):
    x = str(x)
    return x + '@gmail.com'

def getDataFrame(name):
    df = None
    inp = input(f'Name of the file with {name}: ')
    while True:
        try:
            try:
                df = pd.read_csv(DATA_PATH + inp, encoding='ISO-8859-1')
                break
            except:
                pass
            df = pd.read_csv(DATA_PATH + inp + '.csv', encoding='ISO-8859-1')
            break
        except:
            print('File does not exist, please check the file name.')
            inp = input(f'Name of the file with {name}: ')

    df.columns = df.columns.str.upper()
    return df

def getIds(df, col='ID'):
    ids = set(df[col].tolist())
    stringIds = [str(id) for id in ids]
    ids = "', '".join(stringIds)
    ids = f"('{ids}')"
    return ids

def handleCases(df, metaInfo):
    metaInfo.caseIds = getIds(df)
    metaInfo.Cases = df

def handleClaims(df, metaInfo):
    metaInfo.claimIds = getIds(df)
    metaInfo.Claims = df

def handleBookings(df, metaInfo):
    metaInfo.Bookings = df

def handlePassengers(df, metaInfo):
    metaInfo.Passengers = df

def handleCaseToBookings(df, metaInfo):
    metaInfo.CaseToBookings = df
    metaInfo.bookingIds = getIds(df, 'BOOKING__C')

def handleFlights(df, metaInfo):
    metaInfo.Flights = df

def handleFlightIrregularities(df, metaInfo):
    metaInfo.FlightIrregularities = df

def handleSegments(df, metaInfo):
    metaInfo.Segments = df
    metaInfo.flightIds = getIds(df, 'FLIGHT__C')

def handleContentDocumentLinks(df, metaInfo):
    metaInfo.ContentDocumentLinks = df

def handleCustomers(df, metaInfo):
    metaInfo.Customers = df

if __name__ == "__main__":
    main()

