/**
	Apex Rest class for Turi to retrieve a link to a Survey after chat end.
	@author Ludvig Walimaa - Deloitte
*/
@RestResource(urlMapping='/SurveyLink/*')
global without sharing class FCS_RetrieveSurveyLink {

	@HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        C_RestUtil.init();
        try{
            if(Test.isRunningTest()) req.requestBody = Blob.valueOf('o'); //Setting in test due to C_RestUtil.getLogHttpData wont allow a null value. 
            String sessionKey = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        	List<LiveChatTranscript> lctList = [SELECT Id, Case.FCS_SurveyInvitationLink__c FROM LiveChatTranscript WHERE LiveChatVisitor.SessionKey = :sessionKey LIMIT 1];
            if(lctList.size() == 0) C_RestUtil.badRequest('No case with input session key found.');
            C_RestUtil.setOK(lctList[0].Case.FCS_SurveyInvitationLink__c);
        	}catch(Exception e){
                C_RestUtil.handleException(e);      
            }
    }
}