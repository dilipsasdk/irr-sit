global class IRR_BCH_SendAutomatedNoHandBagMessages implements Database.Batchable<sObject> , Database.AllowsCallouts , Schedulable {

    
    
  global Database.QueryLocator start(Database.BatchableContext bc) {
    return IRR_SEL_AutomatedNoHandBagSelector.newInstance().selectAutomatedNoHandBagMessages();
   }
     
     global void execute (
     Database.BatchableContext bc,
     SObject[] sObjScope
   ) {
     
    for ( SObject message : sObjScope ) {
 
       if ( message.get('IRR_Duration__c') != null && message.get('IRR_Departure_Country__c') != null ) {
 
         List<IRR_MOD_PassengerInfo> PaxInfo = IRR_CON_AutomatedCommunication.getPassengerInfos(
           (String)message.get('IRR_Departure_Country__c'),
           (String)message.get('IRR_Arrival_Country__c'),
           (String)message.get('IRR_Duration__c')
         );
         // Why: Send automated messages to passengers(who are not premium EB customers) without handbaggage
         List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
 
         Set<String> stationShortName = new Set<String>();
         for(IRR_MOD_PassengerInfo passengerInfo : PaxInfo) {
          stationShortName.add(passengerInfo.thisSegment.stationArrival);
          stationShortName.add(passengerInfo.thisSegment.stationDeparture);
         }
        
        Map<String,String> airportInfoMap = IRR_SVC_TedsService.getAirportCityNames(stationShortName);        
 
           
           for(IRR_MOD_PassengerInfo passengerInfo : PaxInfo) {
 
             if ((passengerInfo.SSR.contains('LGHT') && !passengerInfo.SSR.contains('CABB')) &&
             (passengerInfo.ebLevel == null || passengerInfo.ebLevel.contains('EBS') || passengerInfo.ebLevel.contains('EBB'))) {

           
              Date dateFormat = Date.valueOf(passengerInfo.thisSegment.departureTimeLocal );
              String monthNameShort =   DateTime.newInstance(dateFormat.year(),dateFormat.month(),dateFormat.day()).format('MMMM');
              passengerInfo.thisSegment.departureTimeLocal =String.valueOf(dateFormat.day()) + ' '+ monthNameShort;
              passengerInfo.thisSegment.arrivalCity = airportInfoMap.get(passengerInfo.thisSegment.stationArrival);
              passengerInfo.thisSegment.departureCity = airportInfoMap.get(passengerInfo.thisSegment.stationDeparture);
              passengerInfo.codsId = 'Checked HBAG for free';
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
         automatedRequest.passengerInfos = passengerInfos;
         automatedRequest.sendSMSMessages = templateName.contains('sms')?false:false;
         automatedRequest.sendEmailMessages = templateName.contains('email')?true:false;
         automatedRequest.emailTemplate = templateName.contains('email')?templateName:null;
         automatedRequest.smsTemplate = templateName.contains('sms')?templateName:null;
           if(passengerInfos.size() > 0){
                IRR_CON_AutomatedCommunication.sendAutomatedCommunication(
           automatedRequest
         );
           }   
        
       }
     }
   }
     
     global void finish(Database.Batchablecontext BC){
         
     }
     
    global void execute(SchedulableContext context) {
     if(!Test.isRunningTest())
     Database.executeBatch(new IRR_BCH_SendAutomatedNoHandBagMessages(),1);
   }
 }