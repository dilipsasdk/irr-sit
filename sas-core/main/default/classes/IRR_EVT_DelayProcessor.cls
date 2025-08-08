/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Event Processor for the Delay event. Inherits and uses functionality from EventProcessor abstract class.
*/

public class IRR_EVT_DelayProcessor extends IRR_EVT_EventProcessor {

    private static final String ERROR_NO_EVENT = 'Delay event info is missing: {0}';
    private static final String ERROR_FLIGHT_ID = 'Flight Id is missing from event: {0}';
    private static final String ERROR_DELAY_MIN = 'Delay minutes is missing from event: {0}';
    private static final String ERROR_DEPT_TIME = 'Estimated time of departure is missing from event: {0}';
    private static final String ERROR_SCHD_TIME = 'Scheduled time of departure is missing from event: {0}';
    private static final String API_DOMAIN_NAME = System.Label.Community_Page_Url;
    private static final String EVENT_FLOW_NAME = 'IRR_EVT_DelayFlow';
    private static final String AIRLINE = 'SK';
    
    private  IRR_EventLog__c currentEventLog = new IRR_EventLog__c();
    private List<IRR_Constant__mdt> delayEventConstant;
    
    @TestVisible
    private IRR_MOD_DelayInfo delayInfo;
    @TestVisible
    private IRR_MOD_ICouponInfo ICouponInfo;
    List<IRR_MOD_PassengerInfo> passengerInfoFilter = new List<IRR_MOD_PassengerInfo>();
    public String getEventName(){
        String eventName = '';
        if(System.Isbatch()){
            eventName = 'Delay - Icoupon';
        }
        else if(delayInfo.isResetEvent == true)
        {
            eventName = 'Delay - Reset';
        }
        else
        {
            eventName = 'Delay';
        }
        return eventName;
    }
    
    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Validates event before processing.
     *      Throws Event Exception if event info is not complete.
     */
    public void validateEvent() {
       
        if (delayInfo == null) {
            throwEventException(ERROR_NO_EVENT, delayInfo);
        }
        if (String.isBlank(delayInfo.flightId)) {
            throwEventException(ERROR_FLIGHT_ID, delayInfo);
        }
        if (delayInfo.delayedMinutes == null) {
            throwEventException(ERROR_DELAY_MIN, delayInfo);
        }
        if (delayInfo.estimatedTimeOfDepartureLocal == null) {
            throwEventException(ERROR_DEPT_TIME, delayInfo);
        }
        if (delayInfo.scheduledTimeOfDepartureUTC == null || delayInfo.scheduledTimeOfDepartureLocal == null) {
            throwEventException(ERROR_SCHD_TIME, delayInfo);
        }
    }
    
    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Populates event object with additional information and initiates passengerInfo list.
     * Added AirportCityNames callout to TEDS to render citynames on the templates
     */
    public void initiateEvent() {
        //Retrieve previous delay and calculate difference
        
        Map<String, Integer> delayMinutesByFlightIds = IRR_SEL_DelayLogsSelector.newInstance()
                .getLatestDelayByFlightIds(new Set<String>{delayInfo.flightId});
        delayInfo.previousDelayedMinutes = delayMinutesByFlightIds.containsKey(delayInfo.flightId) ?
                delayMinutesByFlightIds.get(delayInfo.flightId) : 0;
        
        delayInfo.firstDelay = delayInfo.previousDelayedMinutes == 0;
        delayInfo.delayDifference =Math.abs(delayInfo.delayedMinutes - delayInfo.previousDelayedMinutes);
        if( System.Isbatch()==false){
        IRR_SVC_CommunicationService.FlightIdSplit flightIdSplit =
                new IRR_SVC_CommunicationService.FlightIdSplit(delayInfo.flightId);
        delayInfo.flightRef = flightIdSplit.flightNumber;
        delayInfo.stationDeparture = flightIdSplit.stationDeparture;
        delayInfo.stationArrival = flightIdSplit.stationArrival;
    
        //Retrieve Airport city names from TEDS
        if(delayinfo.stationDeparture != null && delayinfo.stationDeparture != '' 
                && delayinfo.stationArrival != null && delayinfo.stationArrival != ''){
        this.airportInfoMap =IRR_SVC_TedsService.getAirportCityNames(new Set<String>{delayinfo.stationDeparture,delayinfo.stationArrival} );        
        delayInfo.departureCity = airportInfoMap.get(delayinfo.stationDeparture);
        delayInfo.arrivalCity = airportInfoMap.get(delayinfo.stationArrival);
        }
    
        //Calculate time difference of scheduled time of departure and estimated time of departure in minutes
        Long millisecondsToScheduledTime = delayInfo.scheduledTimeOfDepartureUTC.getTime() - Datetime.now().getTime();
        delayInfo.minutesToScheduledTime = (Integer) millisecondsToScheduledTime / 60000;
      }
        this.passengerInfos =  IRR_SVC_TedsService.getPassengerInfosForFlight(delayInfo.flightId);
        if(this.passengerInfos.size() > 0 && System.Isbatch() == true){
            
            for(IRR_MOD_PassengerInfo pass : passengerInfos){
                if(  pass.hasThisSegment == true && 
                     pass.thisSegment.serviceClass != null&& 
                     pass.thisSegment.boardingSequenceNumber != null &&
                     pass.hasBoarded == false &&
                     ( 
                          (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                          (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                          (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'StandBy')  ||
                          (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'StandBy')  
                      ) 
                  ){

    
                      if(pass.thisSegment.seat == null ){
                        pass.thisSegment.seat  = generateRandomNumber();
                      }
                      passengerInfoFilter.add(pass);
                  }
        } 

            getEventLogByFlightNumber(delayInfo.flightId);
            makeRequestForIcoupon();
        }
            
    }
    private static String generateRandomNumber() {
        // Generate a random number using your desired logic
        // For example, you can use a combination of digits and letters
         
        // Example logic generating a 6-digit alphanumeric random number:
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String randomNumber = '';
        for (Integer i = 0; i < 3; i++) {
            Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomNumber += chars.substring(index, index + 1);
        }
        return randomNumber;
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
        List<IRR_ManualOverride__c> manualOverrides = IRR_SEL_ManualOverridesSelector.newInstance()
                .selectActiveManualOverridesByFlightId(delayInfo.flightId);
        return !manualOverrides.isEmpty();
    }
    
    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Executes flow with for each passenger with event specific information.
     */
    public void processEvent() {
        //Initiate variable container object for Flow
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.delayInfo = delayInfo;
        //Process delay passengers
        if(System.Isbatch()  == false){
            IRR_Shorten_Url__c shortenUrl = IRR_Shorten_Url__c.getValues('EUPassengerRight');
            for (IRR_MOD_PassengerInfo passengerInfo : this.passengerInfos) { 
            

                 //make shorten url for EU Pass right
                
                if(shortenUrl != null && shortenUrl.IRR_EU_Pass_Right_Short_URL__c != Null){
                    passengerInfo.passengerRightURL = shortenUrl.IRR_EU_Pass_Right_Short_URL__c;
                }
                else{
                    passengerInfo.passengerRightURL = System.Label.EU_Passenger_Right;
                }
               
                //Only process passengers confirmed for this segment
                if (passengerInfo.thisSegment != null && !passengerInfo.thisSegment.isConfirmed ) continue;
                //Set passenger info in flowVariables and execute flow
                flowVariables.passengerInfo = passengerInfo;
                executeFlow(EVENT_FLOW_NAME, flowVariables);
           }
        }
        // process icoupon fiter passengers 
        else {
            for (IRR_MOD_PassengerInfo passengerInfo : passengerInfoFilter) { 
                if(passengerInfo.thisSegment.boardingSequenceNumber > currentEventLog.Last_Boarding_Sequence_Number__c && System.Isbatch() && passengerInfo.hasBoarded == false){
                    flowVariables.passengerInfo = passengerInfo;
                    executeFlow(EVENT_FLOW_NAME, flowVariables);
                }
            }
        }
        

 
    }
    
    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Finalizes the event by inserting logs if messages have been created.
     *
     * @param uow Unit of Work
     */
    public override void finalizeEvent(fflib_ISObjectUnitOfWork uow) {
        
        super.finalizeEvent(uow);
        
        if (messages != null && !messages.isEmpty() && System.Isbatch() ==false) {
            insertDelayLog(uow);
            
        }
        if ( delayInfo != null &&  System.Isbatch() == false && delayInfo.delayedMinutes >= 120 && this.passengerInfos.size()>0 && messages != null && !messages.isEmpty())
        {
            insertEventLog(uow);
        }
        
        
    }
    
    
    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Creates a Delay Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertDelayLog(fflib_ISObjectUnitOfWork uow) {
        IRR_DelayLog__c delayLog = new IRR_DelayLog__c();
        delayLog.IRR_FlightId__c = delayInfo.flightId;
        delayLog.IRR_DelayMinutes__c = delayInfo.delayedMinutes;
        uow.registerNew(delayLog);
    }
    
        /**
     * @author Gaurav , Coforge
     * @date 2022
     *
     * @description Creates a Event Log based on event object information and registers it in the Unit of Work.
     *
     * @param uow Unit of Work
     */
    private void insertEventLog(fflib_ISObjectUnitOfWork uow) {
            boolean isEventFound = false;
                // Get a query locator
            Database.QueryLocator sObjectList=   IRR_SEL_EventLogsSelector.newInstance()
                .getQueuedIcouponQueryLocator(delayInfo.flightId);
            
            Database.QueryLocatorIterator it =  sObjectList.iterator();
                // Iterate over the records
                while (it.hasNext())
                {
                IRR_EventLog__c eventLog = (IRR_EventLog__c)it.next();
                eventLog.IRR_ScheduleTime__c = delayInfo.scheduledTimeOfDepartureUTC;
                eventLog.IRR_FlightId__c =delayInfo.flightId ;
                eventLog.IRR_Event_Type__c = 'ICOUPON';
                eventLog.IRR_Delayed_Minutes__c = delayInfo.delayedMinutes;
                eventLog.IRR_Station_Departure__c = delayInfo.stationDeparture;
                eventLog.IRR_Flight_Ref__c = delayInfo.flightRef;
                eventLog.IRR_EventTime__c = delayInfo.eventTime;
                eventLog.IRR_EstimatedTime_Of_DepartureUTC__c = delayInfo.estimatedTimeOfDepartureUTC;
                uow.registerUpsert(eventLog);
                isEventFound = true ;
                }
            
                if(isEventFound == false){
                IRR_Pause_Flight_Icoupons__c pausedFlights = IRR_Pause_Flight_Icoupons__c.getValues(delayInfo.stationDeparture);
                List<String> flightNumbers = new List<String>();
                    if(pausedFlights != Null && pausedFlights.Flight_Ref__c != Null && pausedFlights.Flight_Ref__c != ''){
                    flightNumbers = pausedFlights.Flight_Ref__c.split(',');
                }
                List<IRR_Icoupon_Voucher__mdt> icouponVocuherMtd = IRR_SEL_IcouponVoucherSelector.newInstance().getIcouponVoucher();
                for(IRR_Icoupon_Voucher__mdt icouponVocuher :icouponVocuherMtd){
                if(icouponVocuher.AirportCode__c == delayInfo.stationDeparture  &&  
                ( 
                    pausedFlights ==null || 
                    pausedFlights.Is_Paused__c == false || 
                    (!flightNumbers.contains(delayInfo.flightRef) && flightNumbers.size() > 0 && pausedFlights.Is_Paused__c == true )
                ) 
                ){
                IRR_EventLog__c eventLog = new IRR_EventLog__c();
                decimal eventScheduleTimeDiff = ((delayInfo.eventTime.getTime())/1000/60) - ((delayInfo.scheduledTimeOfDepartureUTC.getTime())/1000/60);
                decimal eventEstimatedTimeDiff = ((delayInfo.estimatedTimeOfDepartureUTC.getTime())/1000/60)- ((delayInfo.eventTime.getTime())/1000/60);
                if(eventScheduleTimeDiff >= 0 && eventEstimatedTimeDiff >= 0){
                  eventLog.IRR_ScheduleTime__c = delayInfo.eventTime.addMinutes(10);
                }
                else{
                    eventLog.IRR_ScheduleTime__c = delayInfo.scheduledTimeOfDepartureUTC;
                }
                eventLog.IRR_FlightId__c =delayInfo.flightId ;
                eventLog.IRR_Event_Type__c = 'ICOUPON';
                eventLog.IRR_Delayed_Minutes__c = delayInfo.delayedMinutes;
                eventLog.IRR_Station_Departure__c = delayInfo.stationDeparture;
                eventLog.IRR_Flight_Ref__c = delayInfo.flightRef;
                eventLog.IRR_EventTime__c = delayInfo.eventTime;
                eventLog.IRR_EstimatedTime_Of_DepartureUTC__c = delayInfo.estimatedTimeOfDepartureUTC;
                uow.registerNew(eventLog);
                break;
                }
            }
        }
        
    }
    
    
    public IRR_EVT_DelayProcessor(IRR_MOD_DelayInfo delayInfo) {
        this.delayInfo = delayInfo;
       // delayEventConstant = IRR_SEL_ConstantSelector.newInstance().getEventContant('Delay');

    }
    
    public class Constructor implements IRR_EVT_EventProcessor.IConstructable {
        public IRR_EVT_IEventProcessor newInstance(Object payload) {
            return (IRR_EVT_IEventProcessor) new IRR_EVT_DelayProcessor((IRR_MOD_DelayInfo) payload);
        }
    }
    private void getEventLogByFlightNumber(String flightId) {
            // getting pass from event log for those recieved icoupon
            Database.QueryLocator sObjectList = IRR_SEL_EventLogsSelector.newInstance()
            .getQueuedIcouponQueryLocator(flightId);
        
            Database.QueryLocatorIterator it = sObjectList.iterator();
            Set<Integer> boardingSeqNo = new Set<Integer>();
            while (it.hasNext())
            {
            currentEventLog = (IRR_EventLog__c)it.next();
            }   
    }
    
    private Map<String,List<String>> filterPassInfoBySerivceClass() {  
        
        Map<String,List<String>> segmentIdToBoarding = new Map<String,List<String>>();
        for(IRR_MOD_PassengerInfo passenger :passengerInfoFilter){
            if(passenger.thisSegment.boardingSequenceNumber > currentEventLog.Last_Boarding_Sequence_Number__c ){
                        if(!segmentIdToBoarding.containsKey(passenger.thisSegment.serviceClass)){
                            segmentIdToBoarding.put(passenger.thisSegment.serviceClass,new List<String> { });
    
                        }
                    segmentIdToBoarding.get(passenger.thisSegment.serviceClass).add(String.valueOf(passenger.thisSegment.boardingSequenceNumber));
                    
            }
            }
    
            return segmentIdToBoarding ;
    
    }
    
    public void generatePassQrCode(List<IRR_MOD_ICouponInfo> iCouponInfo) { 
             Map<String,IRR_MOD_ICouponInfo> classToAmount = new  Map<String,IRR_MOD_ICouponInfo>();
                for(IRR_MOD_ICouponInfo icouponMod : iCouponInfo){
                    classToAmount.put(icouponMod.serviceClassCode,icouponMod);
                }
                for(IRR_MOD_PassengerInfo passenger : passengerInfoFilter){
                if(passenger.thisSegment.boardingSequenceNumber > currentEventLog.Last_Boarding_Sequence_Number__c ){
                    if(classToAmount.containsKey(passenger.thisSegment.serviceClass)){
                    IRR_MOD_ICouponInfo icoupon =classToAmount.get(passenger.thisSegment.serviceClass);
                        String  str = 'The voucher amount is ' ;
                                str += icoupon.voucherAmount;
                                str += ' '+icoupon.currencyCode;
                                str += '.';
                        passenger.thisSegment.couponAmount = icoupon.voucherAmount;
                        passenger.thisSegment.currencyCode = icoupon.currencyCode;
                        passenger.thisSegment.emailBackBody = str;
                        passenger.thisSegment.couponBatchId = classToAmount.get(passenger.thisSegment.serviceClass).couponBatchId;
                        passenger.thisSegment.qrCodeFormat = IRR_SVC_ICouponService.getQRCodeFormat(passenger);
    
                    }
                }
            }
    }
    
    private void makeRequestForIcoupon() {
        Map<String,List<String>> segmentIdToBoarding = new Map<String,List<String>>();
            // binding segment id with boarding sequence number 
            segmentIdToBoarding = filterPassInfoBySerivceClass();
            // calling icoupon api 
            if(System.Isbatch()==true){
            List<IRR_MOD_ICouponInfo> iCouponInfo = IRR_SVC_ICouponService.createFlightIrregularity(delayInfo,segmentIdToBoarding);
                if(iCouponInfo != null && iCouponInfo.size() > 0){
                    delayInfo.hasCouponBatchId = true;
                    generatePassQrCode(iCouponInfo);
                    makeRequestForShortenUrl();
            }
        }
    }
    public void makeRequestForShortenUrl() {
    
            List<String> qrCodeFormat = new List<String>(); 
            Map<String,String> longShortUrl = new Map<String,String>();
            for(IRR_MOD_PassengerInfo passenger : passengerInfoFilter){
                if(passenger.thisSegment.boardingSequenceNumber > currentEventLog.Last_Boarding_Sequence_Number__c ){
                        String qrCodeString = IRR_SVC_ICouponService.getQRCodeFormat(passenger); 
                               Blob binaryData = Blob.valueOf(qrCodeString);
                               qrCodeString  = API_DOMAIN_NAME + EncodingUtil.base64Encode(binaryData);
                    qrCodeFormat.add(qrCodeString);
            }
        }
            //calling shorten url api
            IRR_MOD_ShortenURL shrtenUrlRes = IRR_SVC_ShortenURLService.generateShortenUrl(qrCodeFormat);
           if(shrtenUrlRes != null && shrtenUrlRes.shortenedUrls != null){
            for(IRR_MOD_ShortenURL.ShortURL shortURL : shrtenUrlRes.shortenedUrls){
                Blob blobContent = EncodingUtil.base64Decode( shortURL.originalUrl.substringAfter('?Id='));
               // Blob to string
               String decodeBase64String = blobContent.toString(); 
                longShortUrl.put(decodeBase64String , shortURL.shortenedUrl);
             }
            }
            for(IRR_MOD_PassengerInfo passenger : passengerInfoFilter){
                if(passenger.thisSegment.boardingSequenceNumber > currentEventLog.Last_Boarding_Sequence_Number__c ){
                    //filter short url based on seat number 
                    for(String mapkey : longShortUrl.keySet()){
                        if(passenger.thisSegment.seat != null && mapkey.Contains(passenger.thisSegment.seat)){
                          passenger.thisSegment.qrCodeSMSLink = longShortUrl.get(mapkey);
                        }
                    }
            }
        } 
    }  
    }