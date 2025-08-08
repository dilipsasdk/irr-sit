/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Controller class for the Manual Communication LWC page.
*/

public class IRR_CON_ManualCommunication {

  private static final String EVENT_TYPE = 'manualCommunication';
  private static final String MSG_TYPE = 'Manual';
  private static final String AIRLINE = 'SK';
  private static final String API_DOMAIN_NAME = System.Label.Community_Page_Url;
  //New variable to indicate the kind of ICoupon voucher (Standard or Standalone)
  public static String iCouponType = '';
  @AuraEnabled
  public static List<IRR_MOD_PassengerInfo> getBookingPassengerInfos(String bookings) {
      String currentBookingReference;
      Set<String> iataCodes = new Set<String>();
      try {
          List<String> splitBookingReferences = bookings.split(',');
          List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
          for (String bookingReference : splitBookingReferences) {
              if (String.isBlank(bookingReference)) continue;
              currentBookingReference = bookingReference;
              passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBooking(bookingReference));
          }
      
          return passengerInfos;
  }
      catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(currentBookingReference + ' - ' + e.getMessage());
          ahe.setMessage(currentBookingReference + ' - ' + e.getMessage());
          throw ahe;
      }
  }

  @AuraEnabled
  public static List<IRR_MOD_PassengerInfo> getAdvancedFilterPassengerInfos(String bookingIds) {
      List<String> currentBookingFilter;
      String departureStation;
      String arrivalStation;
      String departureDate;
      String arrivalDate;
      try {
          List<String> splitBookingFilters = bookingIds.split(',');
          List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
          for (String bookingFilter : splitBookingFilters) {
              if (String.isBlank(bookingFilter)) continue;
              currentBookingFilter = bookingFilter.split('!');
              departureStation = currentBookingFilter.size() >= 1 && String.isNotBlank(currentBookingFilter[0]) ? currentBookingFilter[0] : null ;
              arrivalStation = currentBookingFilter.size() >= 2 && String.isNotBlank(currentBookingFilter[1]) ? currentBookingFilter[1] : null;
              departureDate = currentBookingFilter[2] ;
              arrivalDate = currentBookingFilter[3] ;
              passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation,arrivalStation,departureDate,arrivalDate));
          }
          return passengerInfos;
      }
      catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(currentBookingFilter + ' - ' + e.getMessage());
          ahe.setMessage(currentBookingFilter + ' - ' + e.getMessage());
          throw ahe;
      }
  }

  @AuraEnabled
  public static List<IRR_MOD_PassengerInfo> getFlightPassengerInfos(String flightIds) {
      String currentFlightId;
      try {
          List<String> splitFlightIds = flightIds.split(',');
          List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
          for (String flightId : splitFlightIds) {
              currentFlightId = flightId;
              passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForFlight(flightId));
          }
          return passengerInfos;
      }
      catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(currentFlightId + ' - ' + e.getMessage());
          ahe.setMessage(currentFlightId + ' - ' + e.getMessage());
          throw ahe;
      }
  }

  @AuraEnabled
  public static void sendManualCommunication(IRR_MOD_ManualRequest manualRequest) {
      try {
          IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, manualRequest);
      }
      catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(e.getMessage());
          ahe.setMessage(e.getMessage());
          throw ahe;
      }
  }

  @AuraEnabled
  public static Map<String, List<ManualTemplate>> getManualTemplatesBySendMode() {
      try {
          List<IRR_ManualCommunicationTemplate__mdt> templates = IRR_SEL_ManualTemplatesSelector.newInstance()
                  .selectAllManualCommunicationTemplates();

          Set<String> manualTemplateNames = new Set<String>();
          for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
              //Use SMS template if available, otherwise Email template
              String templateName = String.isNotBlank(mct.IRR_EmailTemplate__c) ? mct.IRR_EmailTemplate__c :
                      mct.IRR_SMSTemplate__c;
              if (!manualTemplateNames.contains(templateName)) {
                  manualTemplateNames.add(templateName);
              }
          }
          //Get Email Templates
          Map<String, EmailTemplate> emailTemplateByNames = IRR_SEL_EmailTemplatesSelector.newInstance()
                  .selectEmailTemplatesByName(manualTemplateNames);

          //Initialize ManualTemplate objects and sort them by Send Mode, skip non-existing Email Templates
          Map<String, List<ManualTemplate>> manualTemplatesBySendMode = new Map<String, List<ManualTemplate>>();
          for (IRR_ManualCommunicationTemplate__mdt mct : templates) {
              String templateName = String.isNotBlank(mct.IRR_EmailTemplate__c) ? mct.IRR_EmailTemplate__c.toLowerCase() :
                      mct.IRR_SMSTemplate__c.toLowerCase();
              if (!emailTemplateByNames.containsKey(templateName)) continue;


              ManualTemplate mt = new ManualTemplate(mct, emailTemplateByNames.get(templateName));
              if (!manualTemplatesBySendMode.containsKey(mct.IRR_SendMode__c)) {
                  manualTemplatesBySendMode.put(mct.IRR_SendMode__c, new List<ManualTemplate>());
              }

              manualTemplatesBySendMode.get(mct.IRR_SendMode__c).add(mt);
          }
          return manualTemplatesBySendMode;
      }
      catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(e.getMessage());
          ahe.setMessage(e.getMessage());
          throw ahe;
      }
  }


@AuraEnabled
  public static List<IRR_Manual_Airport_Timezone__mdt> getTimezoneByAirport() {
      List<IRR_Manual_Airport_Timezone__mdt> airportTimezone;
      try {
          airportTimezone = IRR_SEL_ManualAirportTimezone.newInstance()
                  .getTimezoneByAirport();
          }
       catch (Exception e) {
          AuraHandledException ahe = new AuraHandledException(e.getMessage());
          ahe.setMessage(e.getMessage());
          throw ahe;
      }
      return airportTimezone;
  }

  @AuraEnabled
    public static void sendIcouponManualCommunication(List<IRR_MOD_PassengerInfo> passengerInfo,Integer voucherAmount,String currencyCode,String reasonComment,Boolean isIncludedBoarded){
        Set<Integer> boardingSequences = new Set<Integer>();
        String flightId = '';
        for(IRR_MOD_PassengerInfo pass : passengerInfo){ 
            flightId = pass.thisSegment.flightId;
            if(pass.hasThisSegment == true && pass.thisSegment.boardingSequenceNumber != null ){
                boardingSequences.add(pass.thisSegment.boardingSequenceNumber);
            }
         }
        List<IRR_CommunicationLog__c> icouponSentPass = IRR_SEL_CommunicationLogsSelector.newInstance()
        .getCommunicationLogsByBoardingSequencesIcoupon(boardingSequences,flightId);
        Set<Integer> sentboardingSequenceNumber = new Set<Integer>();
        for(IRR_CommunicationLog__c commLog : icouponSentPass){
            sentboardingSequenceNumber.add(Integer.valueOf(commLog.IRR_BoardingSequence__c));
        }
          List<IRR_MOD_PassengerInfo> passengerInfoFilter = new List<IRR_MOD_PassengerInfo>();
                for(IRR_MOD_PassengerInfo pass : passengerInfo){
                  if( pass.hasThisSegment == true && 
                      pass.thisSegment.serviceClass != null && 
                      pass.thisSegment.boardingSequenceNumber != null && 
                      !sentboardingSequenceNumber.contains(pass.thisSegment.boardingSequenceNumber) &&
                        ( 
                            (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                            (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                            (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'StandBy')  ||
                            (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'StandBy')  
                        ) 
                    ){

      
                        if(pass.thisSegment.seat == null ){
                           pass.thisSegment.seat = generateRandomNumber();
                        }
                        passengerInfoFilter.add(pass);
                    }
          } 

               String iCouponBatchId= '';
               if(passengerInfoFilter.size() > 0 ){
                iCouponBatchId = createIcouponRequestBody(passengerInfoFilter,voucherAmount,reasonComment,isIncludedBoarded);
               }
                if(iCouponBatchId != ''){ 
                    List<IRR_MOD_PassengerInfo> passInfoToSendIcoupon = new List<IRR_MOD_PassengerInfo>();
                    for(IRR_MOD_PassengerInfo passenger : passengerInfoFilter){
                                  String  str  = 'The voucher amount is ' + voucherAmount + ' ' + currencyCode;
                                   passenger.thisSegment.emailBackBody = str;
                                   passenger.thisSegment.qrCodeFormat = IRR_SVC_ICouponService.getQRCodeFormat(passenger);
                                   passenger.thisSegment.isShowBarcode = '';
                                   passenger.thisSegment.couponBatchId = iCouponBatchId;
                                   passenger.thisSegment.currencyCode = currencyCode;
                                   passenger.thisSegment.couponAmount = voucherAmount;
                    
                        //checking pass for boarded or not 
                        if(isIncludedBoarded == false && passenger.hasBoarded == false){
                             passInfoToSendIcoupon.add(passenger);
                          }
                        else if(isIncludedBoarded){
                            passInfoToSendIcoupon.add(passenger);
                         }
                       
                    }

                   if(passInfoToSendIcoupon != null && passInfoToSendIcoupon.size() > 0){
                        IRR_EVT_ManualProcessor objProcessor = new IRR_EVT_ManualProcessor();
                        objProcessor.sendIcouponEmailMessage = true;
                        objProcessor.sendIcouponManualCommunication(passInfoToSendIcoupon);
                    }
                   
        } 
    }
  
  @AuraEnabled
  public static List<IRR_Icoupon_Voucher__mdt> getIcouponMetadata(){
      List<IRR_Icoupon_Voucher__mdt> serviceMtdList = IRR_SEL_IcouponVoucherSelector.newInstance().getIcouponVoucher();
      return serviceMtdList;
  }
  @AuraEnabled
  public static List<IRR_Manual_Icoupon_Voucher__mdt> getManualIcouponMetadata(){
      List<IRR_Manual_Icoupon_Voucher__mdt> manualIcouponMetadata = IRR_SEL_ManualIcouponVoucherSelector.newInstance().getManualIcouponVoucher();
      return manualIcouponMetadata;
  }

  /*
    New method added for fetching records from Standalone ICoupon Voucher metadata
  */
  @AuraEnabled
  public static List<IRR_Standalone_Icoupon_Voucher__mdt> getStandaloneICouponMetadata(){
      List<IRR_Standalone_Icoupon_Voucher__mdt> standaloneIcouponMetadata = IRR_SEL_StandaloneICouponSelector.newInstance().getStandaloneICouponVoucher();
      return standaloneIcouponMetadata;
  }
//Get commm log by flight id 
  @AuraEnabled
  public static List<IRR_CommunicationLog__c> getCommunicationLogsByFlightIdIcoupon(String flightId,List<Integer> boardingSeqNo){
      List<IRR_CommunicationLog__c> commLog = IRR_SEL_CommunicationLogsSelector.newInstance().getCommunicationLogsByFlightIdIcoupon(flightId,boardingSeqNo);
      return commLog;
  }


  public static void insertCommunicationLogs(List<IRR_MOD_Message> messageList,
  string emailSendStatus,string errorMessage) {
  fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
    new List<Schema.SObjectType>{ IRR_CommunicationLog__c.SObjectType }
  );

  try {
    List<IRR_CommunicationLog__c> logList = new List<IRR_CommunicationLog__c>();

    for (IRR_MOD_Message message : messageList) {
      IRR_CommunicationLog__c log = new IRR_CommunicationLog__c();
      if (message.passengerInfo != null) {
        if (message.passengerInfo.thisSegment != null) {
          log.IRR_FlightId__c = message.passengerInfo.thisSegment.flightId;
        }
        log.IRR_BookingReference__c = message.passengerInfo.bookingReference;
        log.IRR_EBNumber__c = message.passengerInfo.euroBonusNumber;
        log.IRR_CodsId__c = message.passengerInfo.codsId;
        log.IRR_RecipientName__c = message.passengerInfo.lastNameSlashFirstName;
      }

      log.IRR_Channel__c = String.valueOf(message.channel);
      log.IRR_ContactKey__c = message.contactKey;
      log.IRR_MessageKey__c = message.messageKey;
      log.IRR_Recipient__c = message.recipient;
      log.IRR_MessageType__c = MSG_TYPE;
      if (errorMessage != '') {
        log.IRR_ErrorMessage__c = errorMessage;
      }
      log.IRR_Status__c = emailSendStatus;
      log.IRR_MessageContent__c = String.isNotBlank(message.content) &&
        message.content.startsWith('<!DOCTYPE')
        ? message.content.stripHtmlTags()
            .substringBeforeLast(IRR_SVC_CommunicationService.SAS_COPYRIGHT_NOTICE)
        : message.content;

      logList.add(log);
    }
    unitOfWork.registerNew(logList);
    unitOfWork.commitWork();
  } catch (Exception e) {
    system.debug('Exception in insertCommunicationLogs : ' + e.getMessage());
  }
}

@AuraEnabled
public static void sendEmailWithAttachment(
  string fileName,
  string fileType,
  string fileBase64Data,
  IRR_MOD_ManualRequest manualRequest
) {
    List<IRR_MOD_Message> messageList = new List<IRR_MOD_Message>();
  try {

    EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :'irr_manual_message' LIMIT 1];

    String subject = emailTemplate.Subject;
    subject = subject.replace('{{{customInfo.subject}}}',manualRequest.customInfo.subject);

    String htmlBody = emailTemplate.HtmlValue;
    htmlBody = htmlBody.replace('{{{customInfo.content}}}',manualRequest.customInfo.content);

    OrgWideEmailAddress lstOrgWideAddr = new OrgWideEmailAddress();
    lstOrgWideAddr = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Customer Service No Reply' LIMIT 1];

    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    for (IRR_MOD_PassengerInfo passenger : manualRequest.passengerInfos) {

      IRR_MOD_Message message = new IRR_MOD_Message();

      message.channel = IRR_MOD_Message.MessageChannel.EMAIL;
      message.passengerInfo = passenger;
      message.recipient = passenger.emailAddress;

      htmlBody = htmlBody.replace('{{{passengerInfo.emailAddress}}}',passenger.emailAddress);

      message.content = htmlBody;

      Messaging.SingleEmailMessage emails = new Messaging.SingleEmailMessage();

      // Set email properties
      emails.setOrgWideEmailAddressId(lstOrgWideAddr.Id);
      emails.setToAddresses(new List<String>{ passenger.emailAddress });
      emails.setSubject(subject);
      emails.setHtmlBody(htmlBody);

      // Create an email attachment
      Messaging.EmailFileAttachment attachments = new Messaging.EmailFileAttachment();
      attachments.setFileName(fileName);
      attachments.setContentType(fileType);
      attachments.setBody(EncodingUtil.base64Decode(fileBase64Data));

      // Attach the file to the email
      emails.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachments });

      emailList.add(emails);
      messageList.add(message);
    }

    // Send the email
    Messaging.SendEmailResult[] resultss = Messaging.sendEmail(emailList);

    string responseMessage = '';
    string errorMessage = '';
    if (resultss[0].success) {
      responseMessage = 'Created';
    } else {
      responseMessage = 'Error';
      errorMessage = resultss[0].errors[0].message;
      System.debug('The email failed to send: ' + errorMessage);
    }

    insertCommunicationLogs(messageList, responseMessage, errorMessage);

  } catch (Exception e) {
    system.debug('Exception in sendEmailWithAttachment : ' + e.getMessage());
    insertCommunicationLogs(messageList, 'Error', e.getMessage());
  }
}

  public static String createIcouponRequestBody(List<IRR_MOD_PassengerInfo> passengerInfo ,Integer voucherAmount,String reasonComment, Boolean includedBoardedPass){
      String iCouponBatchId = '';
      List<String> boardingSequence = new List<String>();
      String stationDeparture = '';
      String flightNumber = '';
      Date scheduledTimeOfDepartureUTC;
      iCouponType='Standard';
      // binding segment id with boarding sequence number 
       for(IRR_MOD_PassengerInfo passenger : passengerInfo){
           stationDeparture = passenger.thisSegment.stationDeparture ; 
           flightNumber = passenger.thisSegment.flightNumber;
           scheduledTimeOfDepartureUTC = Date.valueOf(passenger.thisSegment.departureTimeUTC);
                
            //checking pass for boarded or not 
                  if(includedBoardedPass == false && passenger.hasBoarded == false && includedBoardedPass ==false){
                      boardingSequence.add(String.valueOf(passenger.thisSegment.boardingSequenceNumber));
                  }
                  else if(includedBoardedPass){
                      boardingSequence.add(String.valueOf(passenger.thisSegment.boardingSequenceNumber));
                  }  
               
          
  
       }
  
       System.debug('boardingSequence +++ ' +  json.serialize(boardingSequence));
       String causingFlightDate = scheduledTimeOfDepartureUTC.Year()+'-'+scheduledTimeOfDepartureUTC.Month()+'-'+scheduledTimeOfDepartureUTC.Day();//'2022-03-15', // delayInfo.scheduledTimeOfDepartureUTC,
       Integer causingFlightNumber = IRR_SVC_ICouponService.getFlightNumber(flightNumber);
  
       Map<String, Object> icoupon = new Map<String, Object>{
           'airportCode' => stationDeparture,
           'causingAirlineCode' => AIRLINE,
           'causingFlightNumber' => causingFlightNumber,
           'causingFlightDate' => causingFlightDate,
           'voucherValue' => voucherAmount,
           'reasonComment' => reasonComment,
           'RedemptionPassDetails' => new Map<String, Object> {
                                   'airlineCode' => AIRLINE,
                                   'flightNumber' => causingFlightNumber,
                                   'flightDate' => causingFlightDate,
            'boardingSequences' => boardingSequence
  
          }
   };
   IRR_SVC_ICouponServiceImpl obj = new IRR_SVC_ICouponServiceImpl();
   IRR_MOD_ICouponInfo icouponRes = boardingSequence.size() > 0 ? obj.callIcouponAPI(icoupon,iCouponType) :null;
   if(icouponRes != null && icouponRes.couponBatchId != null){
      iCouponBatchId = icouponRes.couponBatchId;
      makeRequestForShortenUrl(passengerInfo);
   }
   return iCouponBatchId;
  }
  

  public Static void  makeRequestForShortenUrl(List<IRR_MOD_PassengerInfo> passengerInfos) {

      List<String> qrCodeFormat = new List<String>(); 
      Map<String,String> longShortUrl = new Map<String,String>();
      for(IRR_MOD_PassengerInfo passenger :passengerInfos){
        
                  String qrCodeString = IRR_SVC_ICouponService.getQRCodeFormat(passenger); 
                         Blob binaryData = Blob.valueOf(qrCodeString);
                         qrCodeString  = API_DOMAIN_NAME + EncodingUtil.base64Encode(binaryData);
              qrCodeFormat.add(qrCodeString);
             
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
      for(IRR_MOD_PassengerInfo passenger : passengerInfos){
          
              //filter short url based on seat number 
              for(String mapkey : longShortUrl.keySet()){
                  if(passenger.thisSegment.seat != null &&  mapkey.Contains(passenger.thisSegment.seat)){
                  passenger.thisSegment.qrCodeSMSLink = longShortUrl.get(mapkey);
                  }
              }
      }
    } 
    
    
    public static String generateRandomNumber() {
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
* @author Rati Mehra, Coforge
* @date 2024
* @purpose Method to send out communications for Standalone iCoupon vouchers
*/
  @AuraEnabled
  public static void sendStandaloneIcouponManualCommunication(List<IRR_MOD_PassengerInfo> passengerInfo, Integer voucherAmount, String voucherCurrency, String airportCode,Integer reasonId){
    try{
    List<IRR_Mod_ICouponBatch> standaloneICouponData = createStandaloneIcouponRequestBody(passengerInfo,voucherAmount,airportCode,reasonId);
    List<String> urlFormat = new List<String>(); 
    Map<String,String> shortUrls = new Map<String,String>();
    String urlString = '';
    if(standaloneICouponData != null && standaloneICouponData.size() > 0){
          Map<String, List<String>> iCouponMap = new Map<String, List<String>>();
      for(IRR_Mod_ICouponBatch standaloneICoupon : standaloneICouponData){
          List<String> barcodes = new List<String>();
        if(iCouponMap.containsKey(standaloneICoupon.pnr)){
            barcodes = iCouponMap.get(standaloneICoupon.pnr);
          barcodes.add(standaloneICoupon.barcodes[0]);
        }
        else{
          barcodes.add(standaloneICoupon.barcodes[0]);
        }
      iCouponMap.put(standaloneICoupon.pnr,barcodes);
      }
      List<IRR_MOD_PassengerInfo> passInfoToSendstandaloneICoupon = new List<IRR_MOD_PassengerInfo>();
        Set<String> barcodeSet = new Set<String>();
      for(IRR_MOD_PassengerInfo passenger : passengerInfo){
      //for(IRR_Mod_ICouponBatch standaloneICoupon : standaloneICouponData){
        if(iCouponMap.containsKey(passenger.bookingReference)){
          List<String> barcodes = iCouponMap.get(passenger.bookingReference);
          for(String barcode : barcodes){
            if((passenger.bookingReference == passenger.bookingReference) && (passenger.thisSegment.barcode == null || passenger.thisSegment.barcode == '')
                 && !(barcodeSet.contains(barcode))){
              passenger.thisSegment.barcode = barcode;
                barcodeSet.add(barcode);
              passenger.thisSegment.stationDeparture = airportCode;
              Blob binaryData = Blob.valueOf(passenger.thisSegment.barcode);
              urlString  = API_DOMAIN_NAME + EncodingUtil.base64Encode(binaryData);
              urlFormat.add(urlString);
            }
          }
        }
        /**if((passenger.bookingReference == standaloneICoupon.pnr) && (standaloneICoupon.isIssued == null || standaloneICoupon.isIssued == false)){
                     passenger.thisSegment.barcode = standaloneICoupon.barcodes[0];
                     passenger.bookingReference = standaloneICoupon.pnr;
                     passenger.thisSegment.stationDeparture = airportCode;
                     passenger.thisSegment.couponBatchId = ((standaloneICoupon.couponBatchId).toString());
                     Blob binaryData = Blob.valueOf(passenger.thisSegment.barcode);
                      urlString  = API_DOMAIN_NAME + EncodingUtil.base64Encode(binaryData);
                      urlFormat.add(urlString);
                      standaloneICoupon.isIssued = true;
        }*/
      //}
                      String  str  = 'The voucher amount is ' + voucherAmount + ' ' + voucherCurrency;
                      passenger.thisSegment.emailBackBody = str;
                      passenger.thisSegment.currencyCode = voucherCurrency;
                      passenger.thisSegment.couponAmount = voucherAmount;  
                      passInfoToSendstandaloneICoupon.add(passenger);
    }
  
     //calling shorten url api
     IRR_MOD_ShortenURL shrtenUrlRes = IRR_SVC_ShortenURLService.generateShortenUrl(urlFormat);
     if(shrtenUrlRes != null && shrtenUrlRes.shortenedUrls != null){ 
      for(IRR_MOD_ShortenURL.ShortURL shortURL : shrtenUrlRes.shortenedUrls){
          Blob blobContent = EncodingUtil.base64Decode( shortURL.originalUrl.substringAfter('?Id='));
         // Blob to string
         String decodeBase64String = blobContent.toString(); 
         shortUrls.put(decodeBase64String , shortURL.shortenedUrl);
       }
      }
      for(IRR_MOD_PassengerInfo passenger : passInfoToSendstandaloneICoupon){
          if(iCouponMap.containsKey(passenger.bookingReference)){
          List<String> barcodes = iCouponMap.get(passenger.bookingReference);
          for(String barcode : barcodes){
              if(barcode == passenger.thisSegment.barcode){
                for(String mapkey : shortUrls.keySet()){
                  if(mapkey == barcode){
                    passenger.thisSegment.qrCodeSMSLink = shortUrls.get(mapkey);
                }
              }
            }
          }
        }
          
          
          
          /**for(IRR_Mod_ICouponBatch standaloneICoupon : standaloneICouponData){
          if((passenger.bookingReference == standaloneICoupon.pnr)){
              if(passenger.thisSegment.qrCodeSMSLink == null){
              system.debug('passenger.thisSegment.qrCodeSMSLink>>>>>>>>'+passenger.thisSegment.qrCodeSMSLink);
                  system.debug('standaloneICoupon.barcodes.size()>>>>>>>>'+standaloneICoupon.barcodes.size());
              for(integer i=0;i<standaloneICoupon.barcodes.size();i++){
                      system.debug('barcode value>>>>>>>>>>>'+standaloneICoupon.barcodes[i]);
                  for(String mapkey : shortUrls.keySet()){
                  system.debug('mapkey >>>>>>>>>>'+mapkey);
                if(mapkey == standaloneICoupon.barcodes[i]){
                    system.debug('matched>>>>>>>>>>>>');
                  passenger.thisSegment.qrCodeSMSLink = shortUrls.get(mapkey);
                    system.debug('link set>>>>>>>>>>>>>');
                }
                }
              }
            }
    }
  }*/
  
  }  
    if(passInfoToSendstandaloneICoupon != null && passInfoToSendstandaloneICoupon.size() > 0){
        IRR_EVT_ManualProcessor objProcessor = new IRR_EVT_ManualProcessor();
        objProcessor.sendIcouponEmailMessage = true;
        String iCouponType = 'Standalone';
        objProcessor.sendIcouponManualCommunication(passInfoToSendstandaloneICoupon,iCouponType,airportCode);
    }
   

}
  }
  catch (Exception e) { 
    AuraHandledException ahe = new AuraHandledException(e.getMessage());
    ahe.setMessage(e.getMessage());
    throw ahe;
  }
}

/**
* @author Rati Mehra, Coforge
* @date 2024
* @purpose Method to create the request body for API call for Standalone iCoupon vouchers
*/
  @AuraEnabled
public static List<IRR_Mod_ICouponBatch> createStandaloneIcouponRequestBody(List<IRR_MOD_PassengerInfo> passengerInfo ,Integer voucherAmount,String airportCode,Integer reasonId){

      List<IRR_Mod_ICouponBatch> standaloneICouponBarcodes = new List<IRR_Mod_ICouponBatch>();
      String bookingReference = '';
      String flightNumber = '';
      Date flightDate;
      Date scheduledTimeOfDepartureUTC;
      iCouponType = 'Standalone';
      Integer quantity = 1;
      List<Map<String, Object>> passDetails = new List<Map<String, Object>>();
      // binding pax details 
       for(IRR_MOD_PassengerInfo passenger : passengerInfo){
           flightNumber = passenger.thisSegment.flightNumber;
           scheduledTimeOfDepartureUTC = Date.valueOf(passenger.thisSegment.departureTimeUTC);
           bookingReference = passenger.bookingReference;
           passDetails.add(new Map<String, Object>{
            'pnr' => bookingReference,
            'quantity' => quantity});
       }

       String causingFlightDate = scheduledTimeOfDepartureUTC.Year()+'-'+scheduledTimeOfDepartureUTC.Month()+'-'+scheduledTimeOfDepartureUTC.Day();
       Integer causingFlightNumber = IRR_SVC_ICouponService.getFlightNumber(flightNumber);

      //added for CPH lounge icoupon
      if(airportCode == 'CPH-LOUNGE'){
        airportCode = 'CPH';
    }
       Map<String, Object> icoupon = new Map<String, Object>{
           'airportCode' => airportCode,
           'causingAirlineCode' => AIRLINE,
           'causingFlightNumber' => causingFlightNumber,
           'causingFlightDate' => causingFlightDate,
           'voucherValue' => voucherAmount,
           'customerReasonId' => reasonId,
           'redemptionAirlineCode' => AIRLINE,
           'RedemptionPassDetails' => passDetails
        };
        try{
            IRR_SVC_ICouponServiceImpl obj = new IRR_SVC_ICouponServiceImpl();
            IRR_MOD_ICouponInfo standaloneICouponRes = obj.callIcouponAPI(icoupon,iCouponType);
            if(standaloneICouponRes != null && standaloneICouponRes.couponBatches != null){
              for (IRR_Mod_ICouponBatch couponBatch : standaloneICouponRes.couponBatches){
                standaloneICouponBarcodes.add(couponBatch);
              }
            }
        }
        catch (Exception e) {
              AuraHandledException ahe = new AuraHandledException(e.getMessage());
              ahe.setMessage(e.getMessage());
              throw ahe;
      }
   return standaloneICouponBarcodes;

}
 
  public class ManualTemplate {
      @AuraEnabled
      public String templateLabel;

      @AuraEnabled
      public String templateName;

      @AuraEnabled
      public String emailTemplate;

      @AuraEnabled
      public String smsTemplate;

      @AuraEnabled
      public Boolean defaultSendEmail;

      @AuraEnabled
      public Boolean defaultSendSMS;

      @AuraEnabled
      public String templatePreview;

      @AuraEnabled
      public Boolean responseTemplate;


      public ManualTemplate(IRR_ManualCommunicationTemplate__mdt mct, EmailTemplate et) {
          templateLabel = mct.MasterLabel;
          templateName = mct.DeveloperName;
          emailTemplate = mct.IRR_EmailTemplate__c;
          defaultSendEmail = String.isNotBlank(emailTemplate) && mct.IRR_DefaultSendEmail__c;
          smsTemplate = mct.IRR_SMSTemplate__c;
          defaultSendSMS = String.isNotBlank(smsTemplate) && mct.IRR_DefaultSendSMS__c;
          responseTemplate = mct.IRR_ResponseTemplate__c;
          String templateText = String.isNotBlank(et.HtmlValue) ? et.HtmlValue : et.Body;
          templatePreview = templateText.stripHtmlTags().replace('\n ', '\n')
                  .substringBeforeLast(IRR_SVC_CommunicationService.SAS_COPYRIGHT_NOTICE);
      }
  }
}