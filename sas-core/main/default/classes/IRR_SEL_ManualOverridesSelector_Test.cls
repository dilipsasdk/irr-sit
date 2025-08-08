/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

@IsTest
private class IRR_SEL_ManualOverridesSelector_Test {

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_NoActive_FlightId() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_InActive = new IRR_ManualOverride__c(
                IRR_FlightId__c = 'SK1429-20191104-ARN-CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-2).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(-1).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_FlightId__c = 'AA1425-20191104-ARN-CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_NoMatch_Active, manualOverride_Match_InActive};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(0, manualOverrides.size(), 'No results expected');
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_FlightId() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_FlightId__c = 'SK1429-20191104-ARN-CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_FlightId__c = 'AA1425-20191104-ARN-CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_FlightNumber() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'SK1429',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'AA1425',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_DepartureDate() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_DepartureDate__c = Date.newInstance(2019, 11, 4),
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_DepartureDate__c = Date.newInstance(2019, 12, 4),
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_StationArrival() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_StationArrival__c = 'CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_StationArrival__c = 'ARN',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_StationDeparture() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_StationDeparture__c = 'ARN',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_StationDeparture__c = 'CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_Combined() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'SK1429',
                IRR_DepartureDate__c = Date.newInstance(2019, 11, 4),
                IRR_StationArrival__c = 'CPH',
                IRR_StationDeparture__c = 'ARN',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'AA1429',
                IRR_DepartureDate__c = Date.newInstance(2019, 12, 4),
                IRR_StationArrival__c = 'ARN',
                IRR_StationDeparture__c = 'CPH',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }

    @IsTest
    static void testSelectActiveManualOverridesByFlightId_Active_Overlap() {
        //Given
        Datetime now = Datetime.now();
        IRR_ManualOverride__c manualOverride_Match_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'SK1429',
                IRR_DepartureDate__c = Date.newInstance(2019, 11, 4),
                IRR_StationArrival__c = 'CPH',
                IRR_StationDeparture__c = 'ARN',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        IRR_ManualOverride__c manualOverride_NoMatch_Active = new IRR_ManualOverride__c(
                IRR_FlightNumber__c = 'SK1429',
                IRR_DepartureDate__c = Date.newInstance(2019, 12, 4),
                IRR_StationArrival__c = 'CPH',
                IRR_StationDeparture__c = 'ARN',
                IRR_StartBlockDate__c = now.dateGmt(),
                IRR_StartBlockTime__c = now.addHours(-1).timeGmt(),
                IRR_StopBlockDate__c = now.dateGmt(),
                IRR_StopBlockTime__c = now.addHours(2).timeGmt()
        );
        insert new List<IRR_ManualOverride__c>{manualOverride_Match_Active, manualOverride_NoMatch_Active};

        //When
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId('SK1429-20191104-ARN-CPH');

        //Then
        System.assertEquals(manualOverride_Match_Active.Id, manualOverrides[0].Id);
        System.assertEquals(1, manualOverrides.size());
    }
}