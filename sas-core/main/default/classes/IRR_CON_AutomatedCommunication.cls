/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Controller class for the Automated Communication.
*/

public with sharing class IRR_CON_AutomatedCommunication {
    private static final String EVENT_TYPE = 'automatedCommunication';


    public static List<IRR_MOD_PassengerInfo> getPassengerInfos(String departureStation,String arrivalStation,String daysBeforeDepartureDate ) {
        List<IRR_MOD_PassengerInfo> passengerInfos = new List<IRR_MOD_PassengerInfo>();
        try {
            Date DepartureDate = System.today().addDays(integer.valueOf(daysBeforeDepartureDate));
            String DepDate = String.valueOf(DepartureDate) + 'T00:00:00.000Z';
            Date ArrivalDate = DepartureDate.addDays(2);
            String ArrDate = String.valueOf(ArrivalDate) + 'T00:00:00.000Z';
            List<IRR_MOD_PassengerInfo> paxInfos = new List<IRR_MOD_PassengerInfo>();
            passengerInfos.addAll(IRR_SVC_TedsService.getPassengerInfosForBookingFilters(departureStation,arrivalStation,DepDate,ArrDate));
            DepDate = DepDate.substring(0,10);
            if(passengerInfos.size() > 0){
                for(IRR_MOD_PassengerInfo pInfo: passengerInfos) {
                String DepDateUTC = pInfo.thisSegment.departureTimeUTC.substring(0,10);
                    if(DepDateUTC == DepDate) {
                        paxInfos.add(pInfo);
                    }
                }
            }
            return paxInfos;
        }
        catch (Exception e) {
             System.debug(passengerInfos + ' - ' + e.getMessage());
             throw e;
        }

    }

        public static void sendAutomatedCommunication(IRR_MOD_AutomatedRequest automatedRequest) {
            try {
                IRR_SVC_CommunicationService.processEvent(EVENT_TYPE, automatedRequest);
            }
            catch (Exception e) {
                sendSingleEmailMethod(e);
                System.debug(e.getMessage());
                throw e;
            }
        }
 //send email funcation 
     Public Static void sendSingleEmailMethod(Exception e){
            Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
            String[] toaddresses = new String[] {'chetan.singh@sas.dk','gaurav.singh@sas.dk','ramandeep.singh@sas.dk'};
            mymail.setToAddresses(toAddresses);
            mymail.setReplyTo('chetan.singh@sas.dk');
            mymail.setSenderDisplayName('Error in Salesforce SendAutomatedNoHandBagMessages');
            mymail.setSubject('AutomatedNoHandBagMessages' );
            mymail.setPlainTextBody(e.getMessage() + e.getLineNumber() +e.getCause() +e.getStackTraceString() );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mymail });
       }


        public static ManualTemplate getManualTemplates( String automatedTemplateName) {
            try {


                 Set<String> TemplateName = new Set<String>();
                 templateName.add(automatedTemplateName);

                //Get Email Templates
                Map<String, EmailTemplate> emailTemplateByName = IRR_SEL_EmailTemplatesSelector.newInstance()
                                                                                        .selectEmailTemplatesByName(templateName);
                
                ManualTemplate mt = new ManualTemplate (emailTemplateByName.get(automatedTemplateName));
                return mt;
            }
            catch (Exception e) {
            System.debug('Email templates not found' + ' - ' + e.getMessage());
             throw e;
            }
        }
    
        public class ManualTemplate {
    
            @AuraEnabled
            public String templatePreview;

    
    
            public ManualTemplate(EmailTemplate et) {

                String templateText = String.isNotBlank(et.HtmlValue) ? et.HtmlValue : et.Body;
                templatePreview = templateText.stripHtmlTags().replace('\n ', '\n')
                        .substringBeforeLast(IRR_SVC_CommunicationService.SAS_COPYRIGHT_NOTICE);
            }
        }
    
    }
