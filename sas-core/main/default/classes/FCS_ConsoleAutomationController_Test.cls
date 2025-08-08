/**
 * @author Ludvig Wälimaa
 * @date 2019-11-27
 * Test class for ConsoleAutomationController.
 */

@IsTest
public class FCS_ConsoleAutomationController_Test {
    
    
    /**
	 * Testing getRelated method that will find and return 
     * a list of Object Ids that will opened as a subtab under a 
     * LiveChatTranscript in the Service Cloud Console.
     */ 
    @IsTest
    static void testRetrieveRelatedLiveChatTranscript(){
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv; 
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        insert lct; 
        lct.Status = 'InProgress';
        update lct;
        
        List<Id> caseIds = FCS_ConsoleAutomationController.retrieveRelated(lct.Id);
        Id expCaseId = [SELECT CaseId FROM LiveChatTranscript WHERE Id = :lct.Id].CaseId;
        System.assertEquals(expCaseId, caseIds[0]);
    }
    
    
    
    /**
     * Testing ConsoleAutomationController that will return 
     * a list of prefixes to objects that will be subject to automatically
     * open a subtab in the Service Cloud Console.
     */ 
    @IsTest
    static void testRetrievePrefixes(){
        Test.startTest();
        List<String> prefixList = FCS_ConsoleAutomationController.retrievePrefixes();
        Test.stopTest();
        System.assertNotEquals(null, prefixList);
    }

}