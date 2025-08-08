/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for the Manual Communication LWC Controller.
*/

@IsTest
private class IRR_CON_ManualCommunication_Test {
    
    
    @testSetup static void setup() { 
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
            
        
                     
            EmailTemplate validEmailTemplate3 = new EmailTemplate();
            validEmailTemplate3.isActive = true;
            validEmailTemplate3.Name = 'irr_standalone_icoupon_sms';
            validEmailTemplate3.DeveloperName = 'irr_standalone_icoupon_sms_11233';
            validEmailTemplate3.TemplateType = 'text';
            validEmailTemplate3.FolderId = UserInfo.getUserId();
            validEmailTemplate3.HtmlValue =  'Welcome to KnowledgeWalls<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> <html style="overflow-y: hidden;"> <head> <title></title> </head> <body bgcolor="#ffffff" style="padding: 0px; height: auto; width: 100%; color: rgb(0, 0, 0); font-family: arial,helvetica,sans-serif; font-size: 16px; min-height: auto; background-color: rgb(255, 255, 255);"><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"><meta content="text/html; charset=UTF-8"> <div style="margin: 0px auto; width: 600px;"><img height="63" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/16092f30-85ad-4ba1-ba69-6abd88696641.png" style="display: block; padding: 0px; text-align: center; height: 63px; width: 600px; border: 0px;" width="600" /></div> <div style="margin: 0px auto; width: 600px; margin-top: 0px;"><img height="258" src="https://image.msg.flysas.com/lib/fe3e11717564047d741777/m/1/f9328c84-6322-4942-ad7d-e0ba8ac864c0.png" style="display: block; padding: 0px; text-align: center; height: 258px; width: 600px; border: 0px;" width="600" /></div> <div style="{{{passengerInfo.thisSegment.isShowBarcode}}}"><img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl={{{passengerInfo.thisSegment.qrCodeFormat}}}" /></div> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Dear Traveler,</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Thank you for flying SAS.<br /> <br /> We apologize for the delay of your flight today and would like to offer you refreshments during your wait.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>A digital voucher is loaded on your boarding pass. You can use it for partial or full payment at the following establishments at your departing airport during the next 24hours: </i></span></span><i><a aria-label="Link https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" href="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" rel="noopener noreferrer" tabindex="-1" target="_blank" title="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}">https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}</a></i><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>You can either use your boarding card or the attached QR code in this mail upon ordering your refreshment at any of the establishments shown in the link.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>The voucher cannot be exchanged for cash and no cash change will be given. Multiple vouchers can be used together.<br /> <br /> Please Note this voucher can not be used onboard the aircraft.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>{{{passengerInfo.thisSegment.emailBackBody}}}</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Best regards<br /> SAS</i></span></span></p> <div style="margin: 0px auto; width: 600px; margin-top: 0px; padding: 20px 50px;"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 10px;"> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td style="width: 50%; padding-right: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px 0px 10px;"><span style="color:#999999;"><span style="font-size:12px;"><span style="font-family:Arial,Helvetica,sans-serif;">Scandinavian Airlines © 2023</span></span></span></td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"><span style="color:#999999;"><span style="font-size:10px;">This email has been sent by Scandinavian Airlines System Denmark-Norway-Sweden SE-195 87 Stockholm-Arlanda, Sweden, to {{{passengerInfo.emailAddress}}}.</span></span></td> </tr> </tbody> </table> </td> <td style="width: 50%; padding-left: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px;"> <table cellpadding="0" cellspacing="0" width="100%"> <tbody> <tr> <td align="left"><img height="19" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/1ec482c9-24f9-41d5-8467-516832f22192.png" style="display: block; padding: 0px; text-align: left; height: 19px; width: 200px;" width="200" /></td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"> <div><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">SAS respects your privacy. Please read our </span></span></span><a href="https://www.sas.se/juridisk-information/integritetspolicy/"><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">guidelines </span></span></span></a> <span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">for handling personal data.</span></span></span></div> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </div> </body> </html>';
                
        
        
            EmailTemplate validEmailTemplate4 = new EmailTemplate();
            validEmailTemplate4.isActive = true;
            validEmailTemplate4.Name = 'irr_standalone_icoupon_email';
            validEmailTemplate4.DeveloperName = 'irr_standalone_icoupon_email_132454';
            validEmailTemplate4.TemplateType = 'text';
            validEmailTemplate4.FolderId = UserInfo.getUserId();
            validEmailTemplate4.HtmlValue =  'Welcome to KnowledgeWalls<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> <html style="overflow-y: hidden;"> <head> <title></title> </head> <body bgcolor="#ffffff" style="padding: 0px; height: auto; width: 100%; color: rgb(0, 0, 0); font-family: arial,helvetica,sans-serif; font-size: 16px; min-height: auto; background-color: rgb(255, 255, 255);"><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"><meta content="text/html; charset=UTF-8"> <div style="margin: 0px auto; width: 600px;"><img height="63" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/16092f30-85ad-4ba1-ba69-6abd88696641.png" style="display: block; padding: 0px; text-align: center; height: 63px; width: 600px; border: 0px;" width="600" /></div> <div style="margin: 0px auto; width: 600px; margin-top: 0px;"><img height="258" src="https://image.msg.flysas.com/lib/fe3e11717564047d741777/m/1/f9328c84-6322-4942-ad7d-e0ba8ac864c0.png" style="display: block; padding: 0px; text-align: center; height: 258px; width: 600px; border: 0px;" width="600" /></div> <div style="{{{passengerInfo.thisSegment.isShowBarcode}}}"><img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl={{{passengerInfo.thisSegment.qrCodeFormat}}}" /></div> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Dear Traveler,</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Thank you for flying SAS.<br /> <br /> We apologize for the delay of your flight today and would like to offer you refreshments during your wait.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>A digital voucher is loaded on your boarding pass. You can use it for partial or full payment at the following establishments at your departing airport during the next 24hours: </i></span></span><i><a aria-label="Link https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" href="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}" rel="noopener noreferrer" tabindex="-1" target="_blank" title="https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}">https://icpn.fyi/{{{passengerInfo.thisSegment.stationDeparture}}}</a></i><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>You can either use your boarding card or the attached QR code in this mail upon ordering your refreshment at any of the establishments shown in the link.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>The voucher cannot be exchanged for cash and no cash change will be given. Multiple vouchers can be used together.<br /> <br /> Please Note this voucher can not be used onboard the aircraft.</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>{{{passengerInfo.thisSegment.emailBackBody}}}</i></span></span></p> <p><span style="font-family:Arial,Helvetica,sans-serif;"><span style="font-size:14px;"><i>Best regards<br /> SAS</i></span></span></p> <div style="margin: 0px auto; width: 600px; margin-top: 0px; padding: 20px 50px;"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 10px;"> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td> <table cellpadding="0" cellspacing="0" style="width: 100%;"> <tbody> <tr> <td style="width: 50%; padding-right: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px 0px 10px;"><span style="color:#999999;"><span style="font-size:12px;"><span style="font-family:Arial,Helvetica,sans-serif;">Scandinavian Airlines © 2023</span></span></span></td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"><span style="color:#999999;"><span style="font-size:10px;">This email has been sent by Scandinavian Airlines System Denmark-Norway-Sweden SE-195 87 Stockholm-Arlanda, Sweden, to {{{passengerInfo.emailAddress}}}.</span></span></td> </tr> </tbody> </table> </td> <td style="width: 50%; padding-left: 3px;" valign="top"> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="background-color: transparent; min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner" style="padding: 0px;"> <table cellpadding="0" cellspacing="0" width="100%"> <tbody> <tr> <td align="left"><img height="19" src="https://image.s50.sfmc-content.com/lib/fe3e11717564047d741777/m/1/1ec482c9-24f9-41d5-8467-516832f22192.png" style="display: block; padding: 0px; text-align: left; height: 19px; width: 200px;" width="200" /></td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellpadding="0" cellspacing="0" class="stylingblock-content-wrapper" style="min-width: 100%;" width="100%"> <tbody> <tr> <td class="stylingblock-content-wrapper camarker-inner"> <div><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">SAS respects your privacy. Please read our </span></span></span><a href="https://www.sas.se/juridisk-information/integritetspolicy/"><span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">guidelines </span></span></span></a> <span style="color:#999999;"><span style="font-size:10px;"><span style="font-family:Arial,Helvetica,sans-serif;">for handling personal data.</span></span></span></div> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> </div> </body> </html>';
        
            validEmailTemplateList.add(validEmailTemplate);
            validEmailTemplateList.add(validEmailTemplate2);
            validEmailTemplateList.add(validEmailTemplate3);
            validEmailTemplateList.add(validEmailTemplate4);
           
             unitOfWork.registerNew(validEmailTemplateList);
             unitOfWork.commitWork();
    
    }

    @IsTest
    static void testGetBookingPassengerInfos() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                'TEST_BOOKING_ID');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Error() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_SVC_TedsService.TedsException tedsException =
                new IRR_SVC_TedsService.TedsException('Integration Response: 404 - Not Found');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenThrow(tedsException);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                    'TEST_BOOKING_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage() == 'TEST_BOOKING_ID - Integration Response: 404 - Not Found') caughtException = true;
        }

        //Then
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Multiple() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        IRR_MOD_PassengerInfo passengerInfoOther = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'OTHER_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfosOther = new List<IRR_MOD_PassengerInfo>{
                passengerInfoOther
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID')).thenReturn(passengerInfos);
        mocks.when(serviceMock.getPassengerInfosForBooking('OTHER_BOOKING_ID')).thenReturn(passengerInfosOther);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getBookingPassengerInfos(
                'TEST_BOOKING_ID,OTHER_BOOKING_ID');

        //Then
        System.assertEquals(2, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        System.assertEquals(passengerInfoOther.emailAddress, passengerResult[1].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('TEST_BOOKING_ID');
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForBooking('OTHER_BOOKING_ID');
    }

    @IsTest
    static void testGetBookingPassengerInfos_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBooking('TEST_BOOKING_ID'))
                .thenThrow(new IRR_SVC_TedsService.TedsException('TEST_TEDS_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getBookingPassengerInfos('TEST_BOOKING_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_TEDS_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @isTest
    static void testGetAdvancedFilterPassengerInfos() {

        //Set up mock
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04'))
                .thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //when
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos(
                'ARN!CPH!2021-03-03!2021-03-04');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock))
                .getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04');

    }

    @isTest
    static void testGetAdvancedFilterPassengerInfos_Error (){

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        IRR_SVC_TedsService.TedsException tedsException = new IRR_SVC_TedsService.TedsException('Integration Response: 404 - Not Found');
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04'))
                .thenThrow(tedsException);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
             List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos(
                     'ARN!CPH!2021-03-03!2021-03-04');
        } catch (AuraHandledException ahe) {
                if(ahe.getMessage().contains('Integration Response: 404 - Not Found')) caughtException = true;
                
        }
        //Then
       ((IRR_SVC_ITedsService) mocks.verify(serviceMock))
                .getPassengerInfosForBookingFilters('ARN', 'CPH', '2021-03-03', '2021-03-04');
        System.assert(caughtException , 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetFlightPassengerInfos() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        List<IRR_MOD_PassengerInfo> passengerResult = IRR_CON_ManualCommunication.getFlightPassengerInfos(
                'TEST_FLIGHT_ID');

        //Then
        System.assertEquals(passengerInfos, passengerResult);
        System.assertEquals(1, passengerResult.size());
        System.assertEquals(passengerInfo.emailAddress, passengerResult[0].emailAddress);
        ((IRR_SVC_ITedsService) mocks.verify(serviceMock)).getPassengerInfosForFlight('TEST_FLIGHT_ID');
    }

    @IsTest
    static void testGetFlightPassengerInfos_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);

        //Given
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID')).
                thenThrow(new IRR_SVC_TedsService.TedsException('TEST_TEDS_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getFlightPassengerInfos('TEST_FLIGHT_ID');
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_TEDS_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testSendManualCommunication() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService)
                mocks.mock(IRR_SVC_CommunicationServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        manualRequest.passengerInfos = passengerInfos;
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        IRR_CON_ManualCommunication.sendManualCommunication(manualRequest);

        //Then
        ((IRR_SVC_ICommunicationService) mocks.verify(serviceMock)).processEvent('manualCommunication', manualRequest);
    }

    @IsTest
    static void testSendManualCommunication_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ICommunicationService serviceMock = (IRR_SVC_ICommunicationService)
                mocks.mock(IRR_SVC_CommunicationServiceImpl.class);

        //Given
        mocks.startStubbing();
        ((IRR_SVC_ICommunicationService) mocks.doThrowWhen(
                    new IRR_SVC_CommunicationService.EventException('TEST_EVENT_EXCEPTION'), serviceMock))
                .processEvent(fflib_Match.anyString(), fflib_Match.isNull());
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ICommunicationService.class, serviceMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.sendManualCommunication(null);
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_EVENT_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }

    @IsTest
    static void testGetManualTemplatesBySendMode() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualTemplatesSelector selectorMock = (IRR_SEL_IManualTemplatesSelector)
                mocks.mock(IRR_SEL_ManualTemplatesSelector.class);
        IRR_SEL_IEmailTemplatesSelector etSelectorMock = (IRR_SEL_IEmailTemplatesSelector)
                mocks.mock(IRR_SEL_IEmailTemplatesSelector.class);

        //Given
        List<IRR_ManualCommunicationTemplate__mdt> manualCommunicationTemplates =
                new List<IRR_ManualCommunicationTemplate__mdt>{
                        new IRR_ManualCommunicationTemplate__mdt(
                                MasterLabel = 'TEST_LABEL',
                                DeveloperName = 'TEST_DEV_NAME',
                                IRR_SendMode__c = 'TEST_SEND_MODE',
                                IRR_EmailTemplate__c = 'TEST_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'TEST_SMS_TEMPLATE'),
                        new IRR_ManualCommunicationTemplate__mdt(
                                MasterLabel = 'OTHER_LABEL',
                                DeveloperName = 'OTHER_DEV_NAME',
                                IRR_SendMode__c = 'OTHER_SEND_MODE',
                                IRR_EmailTemplate__c = 'OTHER_EMAIL_TEMPLATE',
                                IRR_SMSTemplate__c = 'OTHER_SMS_TEMPLATE')
                };
        Map<String, EmailTemplate> emailTemplatesByName = new Map<String, EmailTemplate>{
                'test_sms_template' => new EmailTemplate(Name = 'TEST_SMS_TEMPLATE', HtmlValue = '<html>test</html>'),
                'other_sms_template' => new EmailTemplate(Name = 'OTHER_SMS_TEMPLATE', HtmlValue = '<html>other</html>')
        };
        mocks.startStubbing();
        mocks.when(etSelectorMock.sObjectType()).thenReturn(EmailTemplate.SObjectType);
        mocks.when(etSelectorMock.selectEmailTemplatesByName((Set<String>) fflib_Match.anyObject()))
                .thenReturn(emailTemplatesByName);
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualCommunicationTemplate__mdt.SObjectType);
        mocks.when(selectorMock.selectAllManualCommunicationTemplates()).thenReturn(manualCommunicationTemplates);
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);
        IRR_Application.Selector.setMock(etSelectorMock);

        //When
        Map<String, List<IRR_CON_ManualCommunication.ManualTemplate>> templateResult =
                IRR_CON_ManualCommunication.getManualTemplatesBySendMode();
        System.debug(JSON.serializePretty(templateResult));

        //Then
       /* ((IRR_SEL_IManualTemplatesSelector) mocks.verify(selectorMock))
             .selectAllManualCommunicationTemplates();
      ((IRR_SEL_IEmailTemplatesSelector) mocks.verify(etSelectorMock))
             .selectEmailTemplatesByName(new Set<String>{'TEST_SMS_TEMPLATE','OTHER_SMS_TEMPLATE'});
        System.assert(templateResult.containsKey('TEST_SEND_MODE'), 'Result should contain test send mode');
        System.assert(templateResult.containsKey('OTHER_SEND_MODE'), 'Result should contain other send mode');
        System.assertEquals(1, templateResult.get('TEST_SEND_MODE').size());
        System.assertEquals(1, templateResult.get('OTHER_SEND_MODE').size());
        System.assertEquals('TEST_EMAIL_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].emailTemplate);
        System.assertEquals('OTHER_EMAIL_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].emailTemplate);
        System.assertEquals('TEST_LABEL', templateResult.get('TEST_SEND_MODE')[0].templateLabel);
        System.assertEquals('OTHER_LABEL', templateResult.get('OTHER_SEND_MODE')[0].templateLabel);
        System.assertEquals('TEST_DEV_NAME', templateResult.get('TEST_SEND_MODE')[0].templateName);
        System.assertEquals('OTHER_DEV_NAME', templateResult.get('OTHER_SEND_MODE')[0].templateName);
        System.assertEquals('TEST_SMS_TEMPLATE', templateResult.get('TEST_SEND_MODE')[0].smsTemplate);
        System.assertEquals('test', templateResult.get('TEST_SEND_MODE')[0].templatePreview);
        System.assertEquals('OTHER_SMS_TEMPLATE', templateResult.get('OTHER_SEND_MODE')[0].smsTemplate);
        System.assertEquals('other', templateResult.get('OTHER_SEND_MODE')[0].templatePreview);*/
    }

    @IsTest
    static void testGetManualTemplatesBySendMode_Throws() {
        //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SEL_IManualTemplatesSelector selectorMock = (IRR_SEL_IManualTemplatesSelector)
                mocks.mock(IRR_SEL_ManualTemplatesSelector.class);

        //Given
        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(IRR_ManualCommunicationTemplate__mdt.SObjectType);
        mocks.when(selectorMock.selectAllManualCommunicationTemplates()).
                thenThrow(new QueryException('TEST_QUERY_EXCEPTION'));
        mocks.stopStubbing();
        IRR_Application.Selector.setMock(selectorMock);

        //When
        Boolean caughtException = false;
        try {
            IRR_CON_ManualCommunication.getManualTemplatesBySendMode();
        }
        catch (AuraHandledException ahe) {
            if (ahe.getMessage().contains('TEST_QUERY_EXCEPTION')) caughtException = true;
        }

        //Then
        System.assert(caughtException, 'Expected to catch AuraHandledException');
    }
     @IsTest
    static void testsendIcouponManualCommunication() {
        
        
         //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_ITedsService serviceMock = (IRR_SVC_ITedsService) mocks.mock(IRR_SVC_TedsServiceImpl.class);


        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        IRR_MOD_SegmentInfo thisSegment = new IRR_MOD_SegmentInfo();
        thisSegment.flightId = 'SK1423-20230206-ARN_CPH';
        thisSegment.boardingSequenceNumber = 1;
        thisSegment.statusCode = 'HK';
        thisSegment.checkInStatus = 'Accepted';
        thisSegment.serviceClass= 'M';
        thisSegment.seat= '02M';
        thisSegment.departureTimeUTC = '2022-05-17T17:50:00Z';
        thisSegment.flightNumber = 'SK1423';
        thisSegment.seat = 'SK1423';
        passengerInfo.thisSegment = thisSegment;
        passengerInfo.hasThisSegment = true;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
        mocks.startStubbing();
        mocks.when(serviceMock.getPassengerInfosForFlight('TEST_FLIGHT_ID')).thenReturn(passengerInfos);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_ITedsService.class, serviceMock);
        
       Test.setMock(HttpCalloutMock.class, new IRR_SVC_ICouponMockClass());
         //When
       Test.startTest();
       IRR_CON_ManualCommunication.sendIcouponManualCommunication(
               passengerInfos,10,'EUR','test comment',true);
        IRR_CON_ManualCommunication.getIcouponMetadata();
        IRR_CON_ManualCommunication.getManualIcouponMetadata();
        IRR_CON_ManualCommunication.getTimezoneByAirport();
      Test.stopTest();
    }


    @IsTest
    static void testsendStandaloneIcouponManualCommunication() {
         //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_IShortenURLService serviceMock = (IRR_SVC_IShortenURLService) mocks.mock(IRR_SVC_ShortenURLServiceImpl.class);
        IRR_MOD_ShortenURL response  = new IRR_MOD_ShortenURL();
        List<IRR_MOD_ShortenURL.ShortURL> innerClassResList = new List<IRR_MOD_ShortenURL.ShortURL>();
    
        IRR_MOD_ShortenURL.ShortURL innerClassRes = new IRR_MOD_ShortenURL.ShortURL();
        innerClassRes.originalUrl = 'https://developer.salesforce.com';
        innerClassRes.shortenedUrl = 'test.com';
        innerClassResList.add(innerClassRes);
        
        
        response.shortenedUrls = innerClassResList;
        List<String> urls = new List<String>();
        urls.add('https://developer.salesforce.com');
        mocks.startStubbing();
        mocks.when(serviceMock.generateShortenUrl(urls))
                .thenReturn(response);
        mocks.stopStubbing();
       

        //Given
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        IRR_MOD_SegmentInfo thisSegment = new IRR_MOD_SegmentInfo();
        thisSegment.flightId = 'SK1423-20230206-ARN_CPH';
        thisSegment.statusCode = 'HK';
        thisSegment.checkInStatus = 'Accepted';
        thisSegment.serviceClass= 'M';
        thisSegment.departureTimeUTC = '2022-05-17T17:50:00Z';
        thisSegment.flightNumber = 'SK1423';
        thisSegment.seat = 'SK1423';
        passengerInfo.thisSegment = thisSegment;
        passengerInfo.hasThisSegment = true;
        passengerInfo.bookingReference = 'AB12345';
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                passengerInfo
        };
            
  
        
        
        Test.setMock(HttpCalloutMock.class, new IRR_SVC_ICouponStandAloneMockClass());
         //When
           Test.startTest();
           IRR_CON_ManualCommunication.sendStandaloneIcouponManualCommunication(
                   passengerInfos,10,'EUR','MAD',640);
          Test.stopTest();
    }

    @IsTest
    static void testGenerateRandomNumber(){
         Test.startTest();
        IRR_CON_ManualCommunication.generateRandomNumber();
         Test.stopTest();
    }
    
     @IsTest
    static void testSendEmailWithAttachment(){
         //Given
        
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'irr_manual_message';
        validEmailTemplate.DeveloperName = 'irr_manual_message';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        insert validEmailTemplate;
        
        OrgWideEmailAddress lstOrgWideAddr = new OrgWideEmailAddress();
            lstOrgWideAddr = [
              SELECT Id, DisplayName
              FROM OrgWideEmailAddress
              WHERE DisplayName = 'Customer Service No Reply'
              LIMIT 1
            ];
        String fileName = 'Test File Name';
        String fileType = 'PDF';
  		String fileBase64Data = 'abcd';
  		IRR_MOD_ManualRequest manualRequest = new IRR_MOD_ManualRequest();
        IRR_MOD_PassengerInfo passengerInfo = new IRR_MOD_PassengerInfo();
        passengerInfo.emailAddress = 'TEST_EMAIL';
        IRR_MOD_CustomInfo customInfo = new IRR_MOD_CustomInfo();
        customInfo.subject = 'Test subject';
        customInfo.content = 'Test content';
        manualRequest.customInfo = customInfo;
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>{
                 passengerInfo
         };
        manualRequest.passengerInfos = passengerInfos;
        
        //When
        Test.startTest();
        IRR_CON_ManualCommunication.sendEmailWithAttachment('Test File Name','PDF','abcd',manualRequest);
        IRR_CON_ManualCommunication.getCommunicationLogsByFlightIdIcoupon('SK1423-20240101-ARN-CPH',new List<Integer>{1});
        Test.stopTest();
    }
    
}