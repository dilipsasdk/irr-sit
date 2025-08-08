/**
    Batch class which ensures that all automated messages and messages to No Hand baggage Passengers are processed
    
    @author Chetan Singh
*/
global with sharing class IRR_BCH_SendAutomatedMessage extends SBS_ScheduledBatch implements Schedulable {
  /**
   overriding the absract method to set batch class Params
   */
  global override void setVariables(
    String obj,
    Integer wipingPeriod,
    string caseField,
    string caseType,
    string batchName,
	string scheduledBatchRunComponentId
  ) {
  }
  public Boolean automatedmessageSSR ;

  public IRR_BCH_SendAutomatedMessage (Boolean automatedmessageSSR){

    this.automatedmessageSSR = automatedmessageSSR;

  }
  
  /**
        Iterates over all Automatedmessage metadata for Automated communication
        @param bc The batch context
    */

  global Database.QueryLocator start(Database.BatchableContext bc) {

    this.setUseTransactionControl(false);

    if(automatedmessageSSR) {

      return IRR_SEL_AutomatedNoHandBagSelector.newInstance().selectAutomatedNoHandBagMessages();

    } else {

      return IRR_SEL_AutomatedMessagesSelector.newInstance().selectAutomatedMessages();
    }

  }
  /**
        Processes the Automatedmessage custom metadata and prepares the Automatedrequest payload
        @param bc The batchable context of the batch job
        @param sObjScope The Automatedmessage custom metadata to process
    */
  global override void executeScope( Database.BatchableContext bc, SObject[] sObjScope ) {

    for ( SObject message : sObjScope ) {

      if ( message.get('IRR_Duration__c') != null && message.get('IRR_Departure_Country__c') != null ) {

        List<IRR_MOD_PassengerInfo> PaxInfo = IRR_CON_AutomatedCommunication.getPassengerInfos(
          (String)message.get('IRR_Departure_Country__c'),
          (String)message.get('IRR_Arrival_Country__c'),
          (String)message.get('IRR_Duration__c')
        );
        // Why: Send automated messages to passengers(who are not premium EB customers) without handbaggage
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();

          for(IRR_MOD_PassengerInfo passengerInfo : PaxInfo) {

            if ((passengerInfo.SSR.contains('LGHT') && !passengerInfo.SSR.contains('CABB')) &&
            (passengerInfo.ebLevel == null || passengerInfo.ebLevel.contains('EBS') || passengerInfo.ebLevel.contains('EBB'))) {
                passengerInfos.add(passengerInfo);
            }

        }
        // ISSUE 21397 :this is to introduce some delay into Batch job 
        for (integer i=0; i<25;i++) {
          Http h = new Http();
        HttpRequest queryReq = new HttpRequest();
        queryReq.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v43.0/limits/');
        queryReq.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        queryReq.setHeader('Content-Type', 'application/json');
        queryReq.setMethod('GET');
        HttpResponse queryRes = h.send(queryReq);

        }

        String templateName = (String)message.get('IRR_Template_Name__c');
        IRR_CON_AutomatedCommunication.ManualTemplate mp = IRR_CON_AutomatedCommunication.getManualTemplates(
          (String)message.get('IRR_Template_Name__c')
        );

        //Why: segregation for generic automated messages and messages to passengers with no hand baggage
        IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
        if(automatedmessageSSR) {
          automatedRequest.passengerInfos = passengerInfos;
        } else {
          automatedRequest.passengerInfos = PaxInfo;
        }
        
        automatedRequest.sendSMSMessages = templateName.contains('sms')?true:false;
        automatedRequest.sendEmailMessages = templateName.contains('email')?true:false;
        automatedRequest.emailTemplate = templateName.contains('email')?templateName:null;
        automatedRequest.smsTemplate = templateName.contains('sms')?templateName:null;
        IRR_CON_AutomatedCommunication.sendAutomatedCommunication(
          automatedRequest
        );
      }
    }
  }

  global override void finishOverridable(Database.BatchableContext bc) {
  }

  global void execute(SchedulableContext ctx) {
    SBS_ScheduledBatch processAutomated = new IRR_BCH_SendAutomatedMessage(automatedmessageSSR);
    ID batchprocessid = Database.executeBatch(processAutomated, 1);
  }
}
