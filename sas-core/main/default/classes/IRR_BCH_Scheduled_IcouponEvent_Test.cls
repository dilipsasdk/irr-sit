/**
* @author Gaurav Singh, CoforgeTech
* @date 2022
*
* @description unit tests for Scheduled Icoupon communication batch
*/
@isTest

public class IRR_BCH_Scheduled_IcouponEvent_Test {
    
    @testSetup static void setup() {
            
              fflib_SObjectUnitOfWork unitOfWork2 = new fflib_SObjectUnitOfWork(
                 new List<Schema.SObjectType>{
                IRR_EventLog__c.SObjectType
                  }
             );         
            List<IRR_EventLog__c> eventLogsList = new List<IRR_EventLog__c>();
            IRR_EventLog__c eventLogs = new IRR_EventLog__c();
            eventLogs.IRR_ScheduleTime__c = System.Now().addHours(2);
            eventLogs.IRR_EventTime__c = System.Now().addHours(1);
            eventLogs.IRR_EstimatedTime_Of_DepartureUTC__c = System.Now().addHours(10);
            eventLogs.IRR_FlightId__c ='SK1429-20191104-AGP-CPH' ;
            eventLogs.IRR_Event_Type__c = 'ICOUPON';
            eventLogs.IRR_Delayed_Minutes__c = 130;
            eventLogs.IRR_Station_Departure__c = 'AGP';
            eventLogs.IRR_Flight_Ref__c = 'SK1429';
            eventLogs.Is_Communication_Send__c = false;
            eventLogs.Is_Second_Communication_Send__c = false;
            eventLogsList.add(eventLogs);
            unitOfWork2.registerNew(eventLogsList);
            unitOfWork2.commitWork();

        
          
    }
    
    
    
    @isTest
    static void testProcessIcouponEventLogs() {
            
             fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
                 new List<Schema.SObjectType>{
                 EmailTemplate.SObjectType
                }
             );        
            List<EmailTemplate> validEmailTemplateList = new List<EmailTemplate>();
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'irr_delay_icoupon_email';
            validEmailTemplate.DeveloperName = 'irr_delay_icoupon_email_14334';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.HtmlValue = 'Welcome to KnowledgeWalls<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> <html style="overflow-y: hidden;"> <head> <title></title> </head> <body bgcolor="#ffffff" style="padding: 0px; height: auto; width: 100%; color: rgb(0, 0, 0); font-family: arial,helvetica,sans-serif; font-size: 16px; min-height: auto; background-color: rgb(255, 255, 255);"><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"><meta content="text/html; charset=UTF-8"> <div style="margin: 0px auto; width: 600px;"><img height="63" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/16092f30-85ad-4ba1-ba69-6abd88696641.png" style="display: block; padding: 0px; text-align: center; height: 63px; width: 600px; border: 0px;" width="600" /></div> <div style="margin: 0px auto; width: 600px; margin-top: 0px;"><img height="258" src="https://image.msg.flysas.com/lib/fe3e11717564047d741777/m/1/f9328c84-6322-4942-ad7d-e0ba8ac864c0.png" style="display: block; padding: 0px; text-align: center; height: 258px; width: 600px; border: 0px;" width="600" /></div> <div style="{{{passengerInfo.thisSegment.isShowBarcode}}}"><img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl={{{passengerInfo.thisSegment.qrCodeFormat}}}" /></div> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Dear Traveler,</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Thank you for flying SAS.<br /> <br /> We apologize for the delay of your flight today and would like to offer you refreshments during your wait.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>A digital voucher is loaded on your boarding pass. You can use it for partial or full payment at the following establishments at your departing airport during the next 24hours: </i></span></span><i><a aria-label="Link https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" href="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" rel="noopener noreferrer" tabindex="-1" target="_blank" title="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}">https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}</a></i><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>You can either use your boarding card or the attached QR code in this mail upon ordering your refreshment at any of the establishments shown in the link.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>The voucher cannot be exchanged for cash and no cash change will be given. Multiple vouchers can be used together.<br /> <br /> Please Note this voucher can not be used onboard the aircraft.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>{{{passengerInfo.thisSegment.emailBackBody}}}</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Best regards<br /> SAS</i></span></span></p> <div style="margin: 0px auto; width: 600px; margin-top: 0px; padding: 20px 50px;"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 10px;"> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td style="width: 50%; padding-right: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px 0px 10px;"><span style="color:#999999;"><span style="font-size:12px;"><span style="font-family:Arial,Helvetica,sans-serif;">Scandinavian Airlines © 2023</span></span></span></td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"><span style="color:#999999;"><span style="font-size:10px;">This email has been sent by Scandinavian Airlines System Denmark-Norway-Sweden SE-195 87 Stockholm-Arlanda, Sweden, to {{{passengerInfo.emailAddress}}}.</span></span></td> </tr> </tbody> </table> </td> <td style="width: 50%; padding-left: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px;"> <table cellpadding="0" cellspacing="0" width="100%"> <tbody> <tr> <td align="left"><img height="19" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/1ec482c9-24f9-41d5-8467-516832f22192.png" style="display: block; padding: 0px; text-align: left; height: 19px; width: 200px;" width="200" /></td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"> <div><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">SAS respects your privacy. Please read our </span></span></span><a href="https://www.sas.se/juridisk-information/integritetspolicy/"><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">guidelines </span></span></span></a> <span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">for handling personal data.</span></span></span></div> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </div> </body> </html>';
            validEmailTemplate.FolderId = UserInfo.getUserId();
        
            EmailTemplate validEmailTemplate2 = new EmailTemplate();
            validEmailTemplate2.isActive = true;
            validEmailTemplate2.Name = 'irr_delay_icoupon_sms';
            validEmailTemplate2.DeveloperName = 'irr_delay_icoupon_sms_3534';
            validEmailTemplate2.TemplateType = 'text';
            validEmailTemplate2.FolderId = UserInfo.getUserId();
            validEmailTemplate2.HtmlValue =  'Welcome to KnowledgeWalls<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> <html style="overflow-y: hidden;"> <head> <title></title> </head> <body bgcolor="#ffffff" style="padding: 0px; height: auto; width: 100%; color: rgb(0, 0, 0); font-family: arial,helvetica,sans-serif; font-size: 16px; min-height: auto; background-color: rgb(255, 255, 255);"><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"><meta content="text/html; charset=UTF-8"> <div style="margin: 0px auto; width: 600px;"><img height="63" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/16092f30-85ad-4ba1-ba69-6abd88696641.png" style="display: block; padding: 0px; text-align: center; height: 63px; width: 600px; border: 0px;" width="600" /></div> <div style="margin: 0px auto; width: 600px; margin-top: 0px;"><img height="258" src="https://image.msg.flysas.com/lib/fe3e11717564047d741777/m/1/f9328c84-6322-4942-ad7d-e0ba8ac864c0.png" style="display: block; padding: 0px; text-align: center; height: 258px; width: 600px; border: 0px;" width="600" /></div> <div style="{{{passengerInfo.thisSegment.isShowBarcode}}}"><img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl={{{passengerInfo.thisSegment.qrCodeFormat}}}" /></div> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Dear Traveler,</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Thank you for flying SAS.<br /> <br /> We apologize for the delay of your flight today and would like to offer you refreshments during your wait.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>A digital voucher is loaded on your boarding pass. You can use it for partial or full payment at the following establishments at your departing airport during the next 24hours: </i></span></span><i><a aria-label="Link https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" href="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" rel="noopener noreferrer" tabindex="-1" target="_blank" title="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}">https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}</a></i><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>You can either use your boarding card or the attached QR code in this mail upon ordering your refreshment at any of the establishments shown in the link.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>The voucher cannot be exchanged for cash and no cash change will be given. Multiple vouchers can be used together.<br /> <br /> Please Note this voucher can not be used onboard the aircraft.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>{{{passengerInfo.thisSegment.emailBackBody}}}</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Best regards<br /> SAS</i></span></span></p> <div style="margin: 0px auto; width: 600px; margin-top: 0px; padding: 20px 50px;"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 10px;"> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td style="width: 50%; padding-right: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px 0px 10px;"><span style="color:#999999;"><span style="font-size:12px;"><span style="font-family:Arial,Helvetica,sans-serif;">Scandinavian Airlines © 2023</span></span></span></td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"><span style="color:#999999;"><span style="font-size:10px;">This email has been sent by Scandinavian Airlines System Denmark-Norway-Sweden SE-195 87 Stockholm-Arlanda, Sweden, to {{{passengerInfo.emailAddress}}}.</span></span></td> </tr> </tbody> </table> </td> <td style="width: 50%; padding-left: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px;"> <table cellpadding="0" cellspacing="0" width="100%"> <tbody> <tr> <td align="left"><img height="19" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/1ec482c9-24f9-41d5-8467-516832f22192.png" style="display: block; padding: 0px; text-align: left; height: 19px; width: 200px;" width="200" /></td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"> <div><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">SAS respects your privacy. Please read our </span></span></span><a href="https://www.sas.se/juridisk-information/integritetspolicy/"><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">guidelines </span></span></span></a> <span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">for handling personal data.</span></span></span></div> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </div> </body> </html>';
            validEmailTemplateList.add(validEmailTemplate2);
            validEmailTemplateList.add(validEmailTemplate);
           
             unitOfWork.registerNew(validEmailTemplateList);
             unitOfWork.commitWork();
            // unitOfWork.registerNew(validEmailTemplateList);
            
             //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IDelayLogsSelector selectorMock = (IRR_SEL_IDelayLogsSelector) mocks.mock(
                IRR_SEL_DelayLogsSelector.class);
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);
        
        

        //Given
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{new IRR_MOD_PassengerInfo()};
        passengerInfos[0].thisSegment = new IRR_MOD_SegmentInfo();
        passengerInfos[0].thisSegment.isConfirmed = true;
        passengerInfos[0].hasThisSegment = true;
        passengerInfos[0].hasPhoneNumber = true;
        passengerInfos[0].phoneNumber = 'TEST_PHONE';
        passengerInfos[0].hasEmailAddress = true;
        passengerInfos[0].emailAddress = 'TEST_EMAIL';
        passengerInfos[0].thisSegment.flightId = 'SK1429-20191104-AGP-CPH';
        passengerInfos[0].thisSegment.flightNumber = 'SK1429';
        passengerInfos[0].bookingReference = 'TEST_BOOKING_REFERENCE';
        passengerInfos[0].thisSegment.serviceClass = 'C';
        passengerInfos[0].thisSegment.statusCode = 'HK';
        passengerInfos[0].thisSegment.seat = null;
        passengerInfos[0].thisSegment.boardingSequenceNumber = 1;
        passengerInfos[0].thisSegment.statusCode = 'HK';
        passengerInfos[0].thisSegment.checkInStatus = 'Accepted';
        passengerInfos[0].thisSegment.departureTimeUTC = String.valueOf(System.now());
        passengerInfos[0].hasBoarded = false;
        Map<String,String> airportInfoMap = new Map<String,String>();
        airportInfoMap.put('FRA','Stockholm');
        airportInfoMap.put('CPH','Copenhagen');
        Map<String, Integer> delayMinutesByFlightIds = new Map<String, Integer>();
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_DelayLog__c.SObjectType);
        mocks.when(selectorMock.getLatestDelayByFlightIds(new Set<String>{'SK1429-20191104-AGP-CPH'}))
                .thenReturn(delayMinutesByFlightIds);
        mocks.when(serviceMock.getPassengerInfosForFlight('SK1429-20191104-AGP-CPH'))
                .thenReturn(passengerInfos);
        mocks.when(serviceMock.getAirportCityNames(new Set<String>{'AGP','CPH'}))
                .thenReturn(airportInfoMap);
        mocks.stopStubbing();
        IRR_MOD_DelayInfo delayInfo = new IRR_MOD_DelayInfo();
        delayInfo.flightId = 'SK1429-20191104-AGP-CPH';
        delayInfo.delayedMinutes = 130;
        delayInfo.scheduledTimeOfDepartureUTC = Datetime.now().addHours(3);
        delayInfo.scheduledTimeOfDepartureLocal = Datetime.now().addHours(4);
        delayInfo.estimatedTimeOfDepartureLocal = Datetime.now().addHours(5);
        delayInfo.stationArrival='CPH';
        delayInfo.stationDeparture='AGP';
        delayInfo.flightRef = 'SK1429';
        IRR_EVT_IEventProcessor eventProcessor = new IRR_EVT_DelayProcessor.Constructor().newInstance(delayInfo);
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
            
        
              Map<String ,List<String>> classWithPassenger = new Map<String ,List<String>>();
              List<String> boardingSequences = new List<String>();
              boardingSequences.add('1');
              classWithPassenger.put('C',boardingSequences);
              Test.setMock(HttpCalloutMock.class, new IRR_SVC_ICouponMockClass());
            // IRR_SVC_ICouponService.createFlightIrregularity(delayInfo,classWithPassenger);
            //When
            Test.startTest();
            IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
            String strSchedule = '0 0 23 * * ?'; 
            //Then
            System.schedule('Sample Test Job', strSchedule, new IRR_BCH_Scheduled_IcouponEvent());
            Test.stopTest();

    }
}