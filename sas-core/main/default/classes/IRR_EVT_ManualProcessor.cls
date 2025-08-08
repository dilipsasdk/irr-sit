/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event processor for the manual messages event.
*/

public class IRR_EVT_ManualProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Manual message request is missing';
    private static final String ERROR_NO_PASSENGERS = 'No passengers to send message to';
    private static final String ERROR_NO_EMAIL_TEMPLATE = 'No Email template selected';
    private static final String ERROR_NO_SMS_TEMPLATE = 'No SMS template selected';
    private static final String ERROR_NO_MESSAGE_TO_SEND = 'There is no message to send';
    private static final String MESSAGE_STATUS_DEFAULT = 'Created';
    public static final String SAS_COPYRIGHT_NOTICE = 'Scandinavian Airlines ©';


    @TestVisible
    private Boolean isQueued = false;

    @TestVisible
    private IRR_MOD_ManualRequest manualRequest;

    public String getEventName() {
        return 'Manual';
    }

    public void validateEvent() {
        if (manualRequest == null) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EVENT);
        }
        if (manualRequest.passengerInfos == null || manualRequest.passengerInfos.isEmpty()) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_PASSENGERS);
        }
        if (manualRequest.sendEmailMessages != null && manualRequest.sendEmailMessages &&
                String.isBlank(manualRequest.emailTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_EMAIL_TEMPLATE);
        }
        if (manualRequest.sendSMSMessages != null && manualRequest.sendSMSMessages &&
                String.isBlank(manualRequest.smsTemplate)) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_SMS_TEMPLATE);
        }
        if (!manualRequest.sendSMSMessages && !manualRequest.sendEmailMessages) {
            throw new IRR_SVC_CommunicationService.EventException(ERROR_NO_MESSAGE_TO_SEND);
        }
    }

    public void initiateEvent() {
        if (manualRequest.sendEmailMessages == null) manualRequest.sendEmailMessages = false;
        if (manualRequest.sendSMSMessages == null) manualRequest.sendSMSMessages = false;
        if (manualRequest.responseMessage == null) manualRequest.responseMessage = false;
        if (manualRequest.sendMessageTime!=null){
            this.isQueued = true;
        } else {
            if (manualRequest.delayInfo != null && String.isNotBlank(manualRequest.delayInfo.flightId)) {
                IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                        new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.delayInfo.flightId);
                manualRequest.delayInfo.flightRef = flightIdSplit.flightNumber;
                manualRequest.delayInfo.stationDeparture = flightIdSplit.stationDeparture;
                manualRequest.delayInfo.stationArrival = flightIdSplit.stationArrival;
                this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames( new Set<String> {flightIdSplit.stationDeparture, flightIdSplit.stationArrival});
                manualRequest.delayInfo.arrivalCity = airportInfoMap.get(flightIdSplit.stationArrival);
                manualRequest.delayInfo.departureCity = airportInfoMap.get(flightIdSplit.stationDeparture);

            }
            if (manualRequest.newInfo != null && String.isNotBlank(manualRequest.newInfo.flightId)) {
                IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                        new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.newInfo.flightId);
                manualRequest.newInfo.flightRef = flightIdSplit.flightNumber;
                manualRequest.newInfo.stationDeparture = flightIdSplit.stationDeparture;
                manualRequest.newInfo.stationArrival = flightIdSplit.stationArrival;
                this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames( new Set<String> {flightIdSplit.stationDeparture, flightIdSplit.stationArrival});
                manualRequest.newInfo.arrivalCity = airportInfoMap.get(flightIdSplit.stationArrival);
                manualRequest.newInfo.departureCity = airportInfoMap.get(flightIdSplit.stationDeparture);
            }
            if (manualRequest.cancelInfo != null && String.isNotBlank(manualRequest.cancelInfo.flightId)) {
                IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                        new IRR_SVC_CommunicationService.FlightIdSplit(manualRequest.cancelInfo.flightId);
                manualRequest.cancelInfo.flightRef = flightIdSplit.flightNumber;
                manualRequest.cancelInfo.stationDeparture = flightIdSplit.stationDeparture;
                manualRequest.cancelInfo.stationArrival = flightIdSplit.stationArrival;
                this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames( new Set<String> {flightIdSplit.stationDeparture, flightIdSplit.stationArrival});
                manualRequest.cancelInfo.arrivalCity = airportInfoMap.get(flightIdSplit.stationArrival);
                manualRequest.cancelInfo.departureCity = airportInfoMap.get(flightIdSplit.stationDeparture);
            }
        }
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Checks if any active manual override blocks exist for this flight.
     *
     * @return If any active manual overrides exist
     */
    public Boolean checkActiveBlock() {
        //Active blocks are currently not applicable for Manual Message event
        return this.isQueued;
    }

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Process passenger infos and create messages according to event info and passenger contact info.
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
        public void processEvent() {
            IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
            flowVariables.customInfo = manualRequest.customInfo;
            flowVariables.delayInfo = manualRequest.delayInfo;
            flowVariables.newInfo = manualRequest.newInfo;
            flowVariables.cancelInfo = manualRequest.cancelInfo;
            flowVariables.scheduledChangeInfo = manualRequest.scheduledChangeInfo;
            //Retrieving airport codes equivalent city names from Teds for Rebooking
            if (manualRequest.delayInfo == null &&  manualRequest.newInfo == null && manualRequest.cancelInfo == null){
                if(manualRequest.passengerInfos!= null && manualRequest.passengerInfos.size()>0) {
                    Set<String> iataCodes = new Set<String>();
                    //List<IRR_MOD_TripInfo> itinerary = new List<IRR_MOD_TripInfo>();
                        for (IRR_MOD_PassengerInfo paxInfo : manualRequest.passengerInfos) {
                            if (paxInfo.itinerary != null && paxInfo.itinerary.size() > 0) {
                                for(IRR_MOD_TripInfo tripInfo: paxInfo.itinerary) {
                                    if(tripInfo.segments!= null && tripInfo.segments.size() > 0) {
                                        for (IRR_MOD_SegmentInfo segInfo: tripInfo.segments) {
                                            iataCodes.add(segInfo.stationArrival);
                                            iataCodes.add(segInfo.stationDeparture);
                                        }
                                    }
                                }
                            }
                        }
                    this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames(iataCodes);
                }
            }
        //calling shorten url api
        IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
        for (IRR_MOD_PassengerInfo passengerInfo : manualRequest.passengerInfos) {
                    if(shortenUrl != null && shortenUrl.IRR_EU_Pass_Right_Short_URL__c != Null){
                        passengerInfo.passengerRightURL = shortenUrl.IRR_EU_Pass_Right_Short_URL__c;
                    }
                    else{
                        passengerInfo.passengerRightURL = System.Label.EU_Passenger_Right;
                    }
            //Fix the issue for shorten url in booking ref in UI
                    if(passengerInfo.hasThisSegment == true){
                        passengerInfo.thisSegment.arrivalCity = this.airportInfoMap.get(passengerInfo.thisSegment.stationArrival);
                        passengerInfo.thisSegment.departureCity = this.airportInfoMap.get(passengerInfo.thisSegment.stationDeparture);
                    }
             //change the message type from manual ui 

                    if(manualRequest.emailTemplate == 'irr_security_italy_email' || manualRequest.smsTemplate == 'irr_security_italy_sms'){
                       passengerInfo.codsId = 'HBAG Light ticket';
                    } 
                Boolean sendEmail = manualRequest.sendEmailMessages;
                Boolean sendSMS = manualRequest.sendSMSMessages;
                //Allow only Rebook event to pass through as other events are being handled in initiate event method
                    if (manualRequest.delayInfo == null &&  manualRequest.newInfo == null && manualRequest.cancelInfo == null){
                        if (passengerInfo.itinerary != null && passengerInfo.itinerary.size() > 0) {
                            for(IRR_MOD_TripInfo tripInfo: passengerInfo.itinerary) {
                                if(tripInfo.segments!= null && tripInfo.segments.size() > 0) {
                                    for (IRR_MOD_SegmentInfo segInfo: tripInfo.segments) {
                                        segInfo.arrivalCity = this.airportInfoMap.get(segInfo.stationArrival);
                                        segInfo.departureCity = this.airportInfoMap.get(segInfo.stationDeparture);
                                    }
                                }
                            }
                        }
                    }
                if (sendEmail || sendSMS) {
                    flowVariables.passengerInfo = passengerInfo;
                    
        
                    createMessages(sendSMS, manualRequest.smsTemplate, sendEmail, manualRequest.emailTemplate,
                        flowVariables, manualRequest.responseMessage);
                }
            }
          //https://dev.azure.com/flysas/Irregularity%20Communication/_workitems/edit/25595
          deduplicateMessages();
        }
     /**
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Finalizes the event by inserting COM logs if messages have been created or inserting Eventlogs if messages were manually scheduled.
     *
     * @param uow Unit of Work
     */
    public override void finalizeEvent(fflib_ISObjectUnitOfWork uow) {

        if(!isQueued){
            super.finalizeEvent(uow);
        }else{
            insertEventLog(uow);
        }
    }

    /**
     * @author Chetan Singh, CoforgeTech
     * @date 2020
     *
     * @description Creates a Event Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertEventLog(fflib_ISObjectUnitOfWork uow) {

        IRR_EventLog__c eventLog = new IRR_EventLog__c();
        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>();
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();

        flowVariables.customInfo = manualRequest.customInfo;
        for(IRR_MOD_PassengerInfo passengerInfo : manualRequest.passengerInfos) {

            flowVariables.passengerInfo = passengerInfo;
        }

        String serializedVariables = JSON.serialize(flowVariables);
        Map<String, Object> templateParams = (Map<String,Object>) JSON.deserializeUntyped(serializedVariables);

        //Reason:We want to store only custom message content in the event log
        
        IRR_MOD_Message emailMessage = new IRR_MOD_Message(MESSAGE_STATUS_DEFAULT, IRR_MOD_Message.MessageChannel.Email,
                templateParams, manualRequest.emailTemplate, flowVariables.passengerInfo, getEventName(), null);
        messages.add(emailMessage);
        

        Set<String> templateNames = new Set<String>();
        for(IRR_MOD_Message message : messages) {
            if (!templateNames.contains(message.template)) {

                templateNames.add(message.template);
            }
        }
        if (templateNames.contains('irr_manual_message')) {

            MSG_IRenderer renderer = IRR_Application.MessageRenderer.newInstance(templateNames);
            for (IRR_MOD_Message message : messages) {
                renderer.renderMessage(message);
            }
        }
        // prepare event log to be inserted

        eventLog.IRR_ScheduleTime__c = manualRequest.sendMessageTime;
        if(manualRequest.passengerInfos != null && manualRequest.passengerInfos.size() > 0) {
            Set<String> flightIds = new Set<String>();
            for(IRR_MOD_PassengerInfo pi : manualRequest.passengerInfos){
                String utcflightId = pi.thisSegment.flightNumber+'-'+((pi.thisSegment.departureTimeUTC).substring(0,10)).replace('-', '')+'-'+pi.thisSegment.stationDeparture+'-'+pi.thisSegment.stationArrival;
                flightIds.add(utcflightId);
                pi.thisSegment.flightId = utcflightId;
            }
            eventLog.IRR_FlightId__c = String.Join(new List<String>(flightIds), ', ');
        }
        for (IRR_MOD_Message message : messages) {
            eventLog.IRR_MessageContent__c = String.isNotBlank(message.content) && message.content.startsWith('<!DOCTYPE') ?
                    message.content.stripHtmlTags().substringBeforeLast(SAS_COPYRIGHT_NOTICE) : message.content;
        }
        
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
                                                new List<Schema.SObjectType>{
                                                        IRR_EventLog__c.SObjectType,
                                                        ContentVersion.SObjectType
                                                }
         );
            String payloadStr = JSON.serialize(manualRequest);
            String fileName ='EventPayload';
            unitOfWork.registerNew(eventLog);

            ContentVersion fileToUpload = new ContentVersion();
            fileToUpload.ContentLocation = 'S';
            fileToUpload.PathOnClient = fileName;
            fileToUpload.Title = fileName;
            fileToUpload.VersionData = Blob.valueOf(payloadStr);

            unitOfWork.registerNew(fileToUpload, ContentVersion.FirstPublishLocationId, eventLog);

            unitOfWork.commitWork();
    }

    
  public IRR_EVT_ManualProcessor(){
    
  }
    public IRR_EVT_ManualProcessor(IRR_MOD_ManualRequest manualRequest) {
        this.manualRequest = manualRequest;
    }

    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_ManualProcessor((IRR_MOD_ManualRequest) payload);
        }
    }
}
