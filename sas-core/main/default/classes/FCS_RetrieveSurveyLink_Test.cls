/**
	Test class for RetrieveSurveyKLink Apex Rest class.
*/
@isTest
public class FCS_RetrieveSurveyLink_Test {
    
	/**
		Test setup
	*/
    @testSetup
    static void setup(){
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.Id;
        insert lct; 
        Case c = new Case();
        c.FCS_SurveyInvitationLink__c = 'test';
        insert c;
        lct.CaseId = c.Id;
        update lct;
        
    }
    
	/**
		Test retrieving a Survey link from a Case by sending a session key as payload.
	*/
    @isTest
    public static void testRetriveSurveyLink(){
		LiveChatVisitor lcv = [SELECT Id, SessionKey FROM LiveChatVisitor LIMIT 1];
        String sessionId = lcv.SessionKey;
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/SurveyLink/' + '1234'; 
            req.httpMethod = 'GET';
            req.addHeader('Content-Type', 'application/json'); 
            RestContext.request = req;
            RestContext.response = res;
        	C_RestUtil.init();
            FCS_RetrieveSurveyLink.doGet();
       Test.stopTest();     
    }

}