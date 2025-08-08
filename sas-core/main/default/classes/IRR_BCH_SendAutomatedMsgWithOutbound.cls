global  class IRR_BCH_SendAutomatedMsgWithOutbound implements Database.Batchable<sObject> , Database.AllowsCallouts , Schedulable
{
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return IRR_SEL_AutomatedMessageSelector.newInstance().getAutomatedMessage();
       }
         
         global void execute ( Database.BatchableContext bc, SObject[] sObjScope) {
            for ( SObject message : sObjScope ) {

                List<String> sources = new List<String>();
                List<String> destinations = new List<String>();
                Integer daysBeforeCommNeedToSend = Integer.valueOf(message.get('Days_Before_Comm_Need_to_Send__c'));  
                String smsTemplateName = String.valueOf(message.get('Sms_Template_Name__c')) ;
                String emailTemplateName = String.valueOf(message.get('Email_Template_Name__c')) ;
     
                Boolean isSMSSend = Boolean.valueOf(message.get('Is_Send_SMS__c')) ;
                Boolean isEmailSend = Boolean.valueOf(message.get('Is_Send_Email__c')) ;  
                Boolean isActive = Boolean.valueOf(message.get('Is_Active__c')) ; 
     
                String type = String.valueOf(message.get('Type__c')) ; 
                String stationArrival = String.valueOf(message.get('Station_Arrival__c')) ;
                String stationDeparture = String.valueOf(message.get('Station_Departure__c')) ;
     
                String outboundArrival = String.valueOf(message.get('Outbound_Station_Arrival__c')) ;
                String outboundDeparture = String.valueOf(message.get('Outbound_Station_Departure__c')) ;
                
             
     
     
                  List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
                  Date DepartureDate = System.today().addDays(daysBeforeCommNeedToSend);
                  String DepDate = String.valueOf(DepartureDate) + 'T00:00:00.000Z';
                  Date ArrivalDate = System.today().addDays(daysBeforeCommNeedToSend + 1);
                  String ArrDate = String.valueOf(ArrivalDate) + 'T00:00:00.000Z';
                  passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(stationDeparture,stationArrival,DepDate,ArrDate));
                  DepDate = DepDate.substring(0,10);
                  List<IRR_MOD_PassengerInfo> paxInfos = new List<IRR_MOD_PassengerInfo>();
                  Set<String> flightId = new  Set<String>();
                  Set<String> sentFlightIds = new  Set<String>();
     
                  //Why: segregation for generic automated messages and messages to passengers with no hand baggage
                  IRR_MOD_AutomatedRequest automatedRequest = new IRR_MOD_AutomatedRequest();
                  
                  
                  if(passengerInfos.size() > 0){
                  
                   for(IRR_MOD_PassengerInfo pInfo: passengerInfos) {
                    String DepDateUTC2 = pInfo.thisSegment.departureTimeUTC.substring(0,10);
                     //current segment setup variable
                    if(DepDateUTC2 == DepDate && type == 'Current') {
                         pInfo.thisSegment.commTypeForEWR  = 'automatedMessageSecurity';
                         paxInfos.add(pInfo);
                        
                         automatedRequest.sendSMSMessages = isSMSSend;
                         automatedRequest.sendEmailMessages = isEMAILSend;
                         automatedRequest.emailTemplate = emailTemplateName;
                         automatedRequest.smsTemplate = smsTemplateName;
                     }
                      //outbound segment setup variable
                     if(DepDateUTC2 == DepDate && type == 'Outbound') {
                         pInfo.thisSegment.commTypeForEWR  = 'automatedMessageSecurity';
                        
                         if(pInfo.hasNextSegment && outboundDeparture == pInfo.nextSegment.stationDeparture && outboundArrival == pInfo.nextSegment.stationArrival) {
                             paxInfos.add(pInfo);
                         }
          
                         automatedRequest.sendSMSMessages = isSMSSend;
                         automatedRequest.sendEmailMessages = isEMAILSend;
                         automatedRequest.emailTemplate = emailTemplateName;
                         automatedRequest.smsTemplate = smsTemplateName;
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
                 
                   automatedRequest.passengerInfos = paxInfos;
                  
                    if(paxInfos.size() > 0){
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
         Database.executeBatch(new IRR_BCH_SendAutomatedMsgWithOutbound(),1);
       }
  
}