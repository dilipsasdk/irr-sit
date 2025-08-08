/**
    Unit tests which ensures that the records created by the test data factory can 
    be inserted in the database.
    @author Peter Södergren
*/
@isTest
private class FCS_TestDataFactory_Test {
    /**
        Tests creating and inserting case records
    */
    @isTest static void insertCaseRecords () {
       insert FCS_TestDataFactory.createCases(200, null, null, C_RecordTypeHelper.CASE_CHANNEL);
    }
    /** 
        Tests creating and inserting account records
    */
    @isTest static void insertAccountRecords(){
        insert FCS_TestDataFactory.createFrequentFlyers(200);
    }

    /** 
        Tests creating and inserting social post records
    */
    @isTest static void insertSocialRecords(){
        insert FCS_TestDataFactory.createSocialPosts(200);
    }

    /**
        Tests creating and inserting user records
    */
    @isTest static void insertUserRecords(){
        insert FCS_TestDataFactory.createUsers(1);
    }
    
}