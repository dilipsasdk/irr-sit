/**
 * Domain class for IRR_SMSResponse__c object
 * @author Peter Södergren
 */
public class IRR_DOM_SMSResponses extends fflib_SObjectDomain {
    /**
     * Instantiates the domain using the supplied list of records
     * @param records The records which the domain instanse should operate on
     */
    public IRR_DOM_SMSResponses(List<IRR_SMSResponse__c> records){
        super(records);
        Configuration.disableTriggerCRUDSecurity();
    }
    /**
     * Before insert logic to update communication log messages
     */
    public override void onBeforeInsert(){
        setCommunicationLogData();
    }
    /**
     * Updates the communication logs of the subscriber keys to register the received message and the
     * most recent date of a message response to a communication log. The most recent communication log 
     * from the same phone number is assumed be the communication being responed to.
     * The sms response is also updated to be related to the communication log.
     * Note: This method does not use an fflib unit of work since it want to log errors rather than propagate them.
     */
    public void setCommunicationLogData(){
        Set<String> recipients = new Set<String>();
        for(IRR_SMSResponse__c sms : (List<IRR_SMSResponse__c>) Records){
            if(!String.isBlank(sms.IRR_InfoFrom__c)){
                recipients.add(sms.IRR_InfoFrom__c);
            }
        }
        if (recipients.isEmpty()) return;

        Map<String, IRR_CommunicationLog__c> comLogByRecipient = IRR_SEL_CommunicationLogsSelector.newInstance()
                .getLatestResponseMessageByRecipients(recipients);

        Boolean prevMode = C_Log.setBuffered(true);
        List<IRR_CommunicationLog__c> comLogsForUpdate = new List<IRR_CommunicationLog__c>();
        for(IRR_SMSResponse__c sms : (List<IRR_SMSResponse__c>) Records){
            if(String.isBlank(sms.IRR_InfoFrom__c) || !comLogByRecipient.containsKey(sms.IRR_InfoFrom__c)) {
                C_Log.log(C_Log.Severity.Warning,
                        'Cannot find related communication log for sms: ' + sms.Id, null, 'SMSResponse', null);
                continue;
            }
            IRR_CommunicationLog__c comLog = comLogByRecipient.get(sms.IRR_InfoFrom__c);
            comLog.IRR_Status__c='Responded';

            //Appending the previous response, discarding long verbs and capping length to 255 characters
            comLog.IRR_Response__c = (sms.IRR_InfoMessageVerb__c!=null && sms.IRR_InfoMessageVerb__c.length()<10 ? sms.IRR_InfoMessageVerb__c + ' ' : '') + sms.IRR_InfoMessageNouns__c + (String.isBlank(comLog.IRR_Response__c) ? '' : ', '+comLog.IRR_Response__c);
            if(comLog.IRR_Response__c.length()>255)comLog.IRR_Response__c = comLog.IRR_Response__c.substring(0,255);

            //Setting the response date of the last response
            Datetime smsTime = sms.IRR_DateUTC__c!=null && sms.IRR_TimeUTC__c!=null ?
                    Datetime.newInstanceGmt(sms.IRR_DateUTC__c,sms.IRR_TimeUTC__c) : sms.CreatedDate;
            if (comLog.IRR_LastResponseDate__c == null || comLog.IRR_LastResponseDate__c < smsTime) {
                comLog.IRR_LastResponseDate__c = smsTime;
            }
            comLogsForUpdate.add(comLog);
            //Relates the sms message to the communication log
            sms.IRR_CommunicationLog__c = comLog.Id;
        }

        try {
            Database.SaveResult[] srList = Database.update(comLogsForUpdate, false);
            for(Integer i=0;i<srList.size();i++){
                Database.SaveResult sr = srList[i];
                if(!sr.isSuccess())C_Log.log(C_Log.Severity.Error, 'Cannot update communication log '+comLogsForUpdate[i].Id+': '+sr.getErrors()[0].getMessage(), null, 'SMSResponse', null);
            }
        }
        catch(Exception e){
            C_Log.logException(e, 'SMSResponse', null);
        }
        C_Log.setBuffered(prevMode);
    }
    
    /**
     * Constructor used to provide reflection support for the domain
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        /**
         * Creates the SMS responses object using the supplied list of records
         * @param records The records with which to instantiate the domain class
         * @return The domain class
         */
        public fflib_SObjectDomain construct(List<SObject> records){
           return new IRR_DOM_SMSResponses(records);
        }
     }
}
