/**
    The class for common logging framework
*/
@isTest
private class C_Log_Test {
    /**
        Test exception which is used to test logging exceptions
    */
    private class TestException extends Exception{}
    
    /**
        Logging using the standard logging method
    */
    @isTest static void logStandard(){
        C_Log.init();
        C_Log.log(C_Log.Severity.Info, 'TEST MESSAGE', null, 'TEST GROUP', null);
        C_Log__c l = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(C_Log.Severity.Info.name(),l.Severity__c);
        System.assertEquals('TEST MESSAGE',l.Message__c);
        System.assertEquals(null,l.StackTrace__c);
        System.assertEquals('TEST GROUP',l.LogGroup__c);
        System.assertNotEquals(null,l.Timestamp__c);
        System.assertNotEquals(null,l.Duration__c);
        System.assert(l.Duration__c>=0);
    }
   /**
        Logging using the standard logging method
    */
     @isTest static void logStandard1(){
        C_Log.init();
        Test.startTest();
        C_Log.log(C_Log.Severity.Error.name(), 'TEST MESSAGE','TEST Stack Race', 'testUser');
        Test.StopTest();
        C_Log__c l = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(C_Log.Severity.Error.name(),l.Severity__c);
        System.assertEquals('TEST MESSAGE',l.Message__c);
        System.assertEquals('TEST Stack Race',l.StackTrace__c);        
    }
    /**
        Logs a message without intializing the log class
    */
    @isTest static void logNoInit(){        
        C_Log.log(C_Log.Severity.Warning, 'TEST MESSAGE', null, 'TEST GROUP', null);
        C_Log__c l = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(C_Log.Severity.Warning.name(),l.Severity__c);
        System.assertEquals('TEST MESSAGE',l.Message__c);
        System.assertEquals(null,l.StackTrace__c);
        System.assertEquals('TEST GROUP',l.LogGroup__c);
        System.assertNotEquals(null,l.Timestamp__c);
        System.assertEquals(null,l.Duration__c);
    }

    /**
        Logs a caught exception
    */
    @isTest static void logException(){
        C_Log.init();
        try{
            throw new TestException('TEST ERROR MESSAGE');
        }
        catch(Exception e){
            C_Log.logException(e, null, null);
        }

        C_Log__c l = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(C_Log.Severity.Error.name(),l.Severity__c);
        System.assertEquals('C_Log_Test.TestException: TEST ERROR MESSAGE',l.Message__c);
        System.assertNotEquals(null,l.StackTrace__c);
        System.assertEquals(null,l.LogGroup__c);
        System.assertNotEquals(null,l.Timestamp__c);
        System.assertNotEquals(null,l.Duration__c);
    }


    /**
        Logs a caught LWC exception
    */
    @isTest static void CreatelogException(){
        C_Log.init();
        try{
            throw new TestException('TEST ERROR MESSAGE');
        }
        catch(Exception e){
            C_Log.createLog('Error', e.getMessage(),e.getStackTraceString(),'LWC');
        }

        List<C_Log__c> lstLogs = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('TEST ERROR MESSAGE',lstLogs[0].Message__c);
        System.assertNotEquals(null,lstLogs[0].StackTrace__c);
        System.assertEquals(1,lstLogs.size());
    }
    /**
        Tests logging a message using a severity which does not exist 
    */
    @isTest static void logIncorrectSeverity(){
        Boolean error = false;
        try{
            C_Log.log(null, 'TEST MESSAGE', null, null, null);
        }
        catch(Exception e){
            error = true;
        }
        System.assertEquals(true,error);
    }

    /**
        Tests logging http errors  
    */
    @isTest static void logHttp(){
        C_Log.HttpData http = new C_Log.HttpData();
        http.resource='/RES';
        http.method='POST';
        http.headers='HEADERS';
        http.queryParams='PARAMS';
        http.remoteAddress='1.2.3.4';
        http.body = 'TEST BODY';
        C_Log.init();
        C_Log.log(C_Log.Severity.Info, 'TEST MESSAGE', null, 'TEST GROUP', http);
        C_Log__c l = [SELECT Id,Severity__c,Message__c,StackTrace__c,LogGroup__c,Timestamp__c,Duration__c,HttpResource__c,HttpMethod__c,HttpHeaders__c,HttpQueryParameters__c,HttpRemoteAddress__c,HttpBody__c FROM C_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(C_Log.Severity.Info.name(),l.Severity__c);
        System.assertEquals('TEST MESSAGE',l.Message__c);
        System.assertEquals(null,l.StackTrace__c);
        System.assertEquals('TEST GROUP',l.LogGroup__c);
        System.assertNotEquals(null,l.Timestamp__c);
        System.assertNotEquals(null,l.Duration__c);

        System.assertEquals(http.resource,l.HttpResource__c);
        System.assertEquals(http.method,l.HttpMethod__c);
        System.assertEquals(http.headers,l.HttpHeaders__c);
        System.assertEquals(http.queryParams,l.HttpQueryParameters__c);
        System.assertEquals(http.remoteAddress,l.HttpRemoteAddress__c);
        System.assertEquals(http.body,l.HttpBody__c);
    }
}