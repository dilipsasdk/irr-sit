global class IRR_BCH_SendAutomatedParisMessages implements Database.Batchable<sObject> , Database.AllowsCallouts , Schedulable,Database.Stateful
    {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return IRR_SEL_AutomatedNoHandBagSelector.newInstance().selectAutomatedSecurityMessagesParis();
       }
         
         global void execute (
         Database.BatchableContext bc,
         SObject[] sObjScope
       ) {
       
        for ( SObject message : sObjScope ) {
             List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
             Date DepartureDate = System.today().addDays(2);
             String DepDate = String.valueOf(DepartureDate) + 'T00:00:00.000Z';
             Date ArrivalDate = System.today().addDays(3);
             String ArrDate = String.valueOf(ArrivalDate) + 'T00:00:00.000Z';
             passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(String.valueOf(message.get('IRR_Departure_Country__c')), String.valueOf(message.get('IRR_Arrival_Country__c')),DepDate,ArrDate));
             DepDate = DepDate.substring(0,10);
             List<IRR_MOD_PassengerInfo> paxInfos = new List<IRR_MOD_PassengerInfo>();
             Set<String> flightId = new  Set<String>();
             Set<String> sentFlightIds = new  Set<String>();
             if(passengerInfos.size() > 0){
                 for(IRR_MOD_PassengerInfo pInfo: passengerInfos) {
                 String DepDateUTC = pInfo.thisSegment.departureTimeUTC.substring(0,10);
                     if(DepDateUTC == DepDate ) {
                        flightId.add(pInfo.thisSegment.flightId);
                     }
                 }
             }
    
             List<IRR_CommunicationLog__c> icouponSentPass = new  List<IRR_CommunicationLog__c>();
             if(flightId.size() > 0){
    
              icouponSentPass = IRR_SEL_CommunicationLogsSelector.newInstance().getCommunicationLogsByFlightIdAndMsgType(flightId,'automatedMessageSecurity');
                
             }
            
    
             //Holding existing comm logs 
             for(IRR_CommunicationLog__c sentMessageFlight : icouponSentPass){
              sentFlightIds.add(sentMessageFlight.IRR_FlightId__c);
             }
    
             
             
             if(passengerInfos.size() > 0){
              for(IRR_MOD_PassengerInfo pInfo: passengerInfos) {
                 String DepDateUTC2 = pInfo.thisSegment.departureTimeUTC.substring(0,10);
                /* Long dt1Long = DateTime.now().getTime();
                 Long dt2Long = DateTime.valueOf(pInfo.thisSegment.departureTimeUTC.replace('T' , ' ')).getTime();
                 Long milliseconds = dt2Long - dt1Long;
                 Long seconds = milliseconds / 1000;
                 Long minutes = seconds / 60;
                 Long hours = minutes / 60;*/
                // System.debug('hours ==== ' + hours);
                  if(DepDateUTC2 == DepDate && ! sentFlightIds.contains(pInfo.thisSegment.flightId)) {
                    pInfo.thisSegment.commTypeForEWR  = 'automatedMessageSecurity';
                    paxInfos.add(pInfo);
    
                  }
              }
          }
    
    
    
               // ISSUE 21397 :this is to introduce some delay into Batch job 
               for (integer i=0; i<25;i++) {
                 Http h = new Http();
                 HttpRequest queryReq = new HttpRequest();
                 queryReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v43.0/limits/');
                 queryReq.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
                 queryReq.setHeader('Content-Type', 'application/json');
                 queryReq.setMethod('GET');
                 HttpResponse queryRes = h.send(queryReq);
         
                 }
            
             //Why: segregation for generic automated messages and messages to passengers with no hand baggage
             IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
             automatedRequest.passengerInfos = paxInfos;
             automatedRequest.sendSMSMessages = true;
             automatedRequest.sendEmailMessages = true;
             automatedRequest.emailTemplate = 'irr_MUC_terminalchange_email';
             automatedRequest.smsTemplate = 'irr_MUC_terminalchange_sms';
               if(passengerInfos.size() > 0){
                    IRR_CON_AutomatedCommunication.sendAutomatedCommunication(
               automatedRequest
             );
               }   
         }
       }
         
         global void finish(Database.Batchablecontext BC){
             
         }
         
        global void execute(SchedulableContext context) {
         if(!Test.isRunningTest())
         Database.executeBatch(new IRR_BCH_SendAutomatedParisMessages(),1);
       }
  
}