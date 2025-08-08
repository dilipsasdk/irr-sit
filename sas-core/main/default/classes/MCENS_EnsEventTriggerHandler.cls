/**
 * Trigger handler responsible for processing platform events 
 * containing events for the Marketing Cloud Event Notification Service.
 * The trigger handler supplies various methods used to process the events
 * @author Peter Södergren
 */
public without sharing class MCENS_EnsEventTriggerHandler {
    /**
     * The minimum number of times to retry processing the events in the batch if messages cannot be found or status cannot be updated
     */
    static final Integer MIN_RETRY_COUNT = 3;
    /**
     * The maximum number of events to process in a single run
     */
    static final Integer MAX_SCOPE_SIZE = 200;
    /**
     * Pattern to check whether the composite id has a UUID prefix
     */
    static final Pattern UUID_PREFIX_PATTERN = Pattern.compile('[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\\..*');
    /**
     * The full list of events which are present in the trigger
     */
    MCENS_EnsEvent__e[] evtSourceList;
    /**
     * Current number of retries performed for the platform event batch
     */
    Integer retryCount;
    /**
     * THe last scope size used if the previous attempt threw a retryable exception
     */
    Integer lastScopeSize;
    /**
     * Whether running the handler in cutoff mode, and errors which may be temporary should not be retried
     */
    Boolean cutoffMode;
    /**
     * The number of events to process
     */
    Integer sz;
    /**
     * The message keys referenced by the events
     */
    String[] messageKeys;
    /**
     * The composite ids referenced by the events
     */
    String[] compositeIds;
    /**
     * Errors occuring due to not finding the appropriate ( will trigger retries)
     */
    String[] notFoundErrors;
    /**
     * General errors occuring due to error with events
     */
    String[] eventErrors;
    /**
     * The list of events processed in scope in the handler
     */
    EnsEvent[] evtList;
    /**
     * The communication log records updated with status from the events
     */
    IRR_CommunicationLog__c[] comLogList;
    /**
     * The replay id of the last processed event
     */
    String lastProcessedReplayId;

    /**
     * Creates a handler for the event trigger handler
     * @param evtSourceList The full list of events which are present in the trigger
     * @param retryCount Current number of retries performed for the platform event batch
     * @param lastError The last error, set if the last attempt threw a retryable exception
     */
    public MCENS_EnsEventTriggerHandler(List<MCENS_EnsEvent__e> evtSourceList, Integer retryCount, String lastError) {
        this.evtSourceList = evtSourceList;
        this.retryCount = retryCount;
        this.lastScopeSize = getLastScopeSize(lastError);

        messageKeys = new List<String>();
        compositeIds = new List<String>();
        notFoundErrors = new List<String>();
        eventErrors = new List<String>();
        cutoffMode = retryCount > MIN_RETRY_COUNT;
    }

    /**
     * Runs the logic of the handler
     * 1. Selects the appropriate events to process, with the cutoff mode in mind
     * 2. Loads the messages which the events relate to
     * 3. Stores the appropriate status updates and logs the appropriate errors
     */
    public void run(){
        selectEvents();
        loadMessages();
        execute();
    }
    /**
     * Selects the events processed in the current batch
     */
    void selectEvents(){
        sz = lastScopeSize!=null ? lastScopeSize : evtSourceList.size();
        if(sz>MAX_SCOPE_SIZE)sz = MAX_SCOPE_SIZE;
        evtList = new EnsEvent[sz];
        for(Integer i=0;i<sz;i++){
            MCENS_EnsEvent__e evt = evtSourceList[i];
            EnsEvent e;
            if(evt.Type__c == 'TransactionalSendEvents.EmailSent')e = new EmailSent(evt);
            else if(evt.Type__c == 'TransactionalSendEvents.EmailNotSent')e = new EmailNotSent(evt);
            else if(evt.Type__c == 'TransactionalSendEvents.EmailBounced')e = new EmailBounced(evt);
            else if(evt.Type__c == 'TransactionalSendEvents.SmsSent')e = new SmsSent(evt);
            else if(evt.Type__c == 'TransactionalSendEvents.SmsNotSent')e = new SmsNotSent(evt);
            else if(evt.Type__c == 'EngagementEvents.EmailOpen')e = new EmailOpen(evt);
            else eventErrors.add('Unknown ENS Event Type: '+evt.Type__c);
            if(e!=null){
                evtList[i] = e;
                if(e.messageKey!=null)messageKeys.add(e.messageKey);
                if(e.compositeId!=null)compositeIds.add(e.compositeId);
            }
        }
    }
    /**
     * Loads the log messages and sets the status of the logs
     */
    void loadMessages(){
        Map<String,IRR_CommunicationLog__c> comLogMap = new Map<String,IRR_CommunicationLog__c>();
        if(!messageKeys.isEmpty() || !compositeIds.isEmpty()){
            try{
                comLogList = [SELECT Id, IRR_MessageKey__c, IRR_CompositeId__c, IRR_Status__c FROM IRR_CommunicationLog__c WHERE IRR_MessageKey__c IN :messageKeys OR IRR_CompositeId__c IN :compositeIds FOR UPDATE];
            }
            catch(DmlException e){
                throwRetryableException('Cannot obtain lock on Communication Logs');
            }
            
            for(Integer i=0,comLogSz=comLogList.size();i<comLogSz;i++){
                IRR_CommunicationLog__c comLog = comLogList[i];
                if(comLog.IRR_MessageKey__c!=null)comLogMap.put(comLog.IRR_MessageKey__c,comLog);
                if(comLog.IRR_CompositeId__c!=null)comLogMap.put(comLog.IRR_CompositeId__c,comLog);
            }
        }
        for(Integer i=0;i<sz;i++){
            EnsEvent evt = evtList[i];
            if(evt!=null){
                IRR_CommunicationLog__c comLog = comLogMap.get(evt.messageKey!=null ? evt.messageKey : evt.compositeId);
                if(comLog!=null){
                    if(evt.compositeId!=null){
                        comLog.IRR_CompositeId__c = evt.compositeId;
                        comLogMap.put(evt.compositeId,comLog);
                    }
                    //Evaluate Integer value of new and old Status to avoid changing Status to a previous value
                    Integer oldStatusValue = IRR_DOM_CommunicationLogs.STATUS_VALUE.get(comLog.IRR_Status__c);
                    Integer newStatusValue = IRR_DOM_CommunicationLogs.STATUS_VALUE.get(evt.getStatus());
                    if (oldStatusValue == null || newStatusValue == null || newStatusValue > oldStatusValue) {
                        evt.setStatus(comLog);
                    }
                }
                else {                
                    notFoundErrors.add('Cannot find matching communication log: '+evt.messageKey+'/'+evt.compositeId);
                }
            }
        }
    }
    /**
     * Commits DML depending upon mode.
     * If not in cutoff mode with not found errors:
     * - Commit nothing
     * - Throw retry exception
     * Otherwise:
     * - Log not found errors
     * - Log event errors
     * - Update communication log records
     */
    void execute(){
        if(!cutoffMode && !notFoundErrors.isEmpty()){
            throwRetryableException(notFoundErrors.size()+'/'+sz+' messages not found, 1st error: '+notFoundErrors[0]);
        }
        else {
            Boolean prevBufferMode = C_Log.setBuffered(true);
            for(String err : eventErrors){
                C_Log.log(C_Log.Severity.Error, err, null, 'MCENS', null);
            }
            if(!prevBufferMode)C_Log.flush();
            C_Log.setBuffered(prevBufferMode);
            if(comLogList!=null)update comLogList;
            lastProcessedReplayId = evtSourceList[sz-1].ReplayId;
        }
    }

    /**
     * Throws a retryable exception containing the supplied message and current scope size
     * The current scope size is used to continue operating on the same scope when retrying
     * @param message The error message
     */
    void throwRetryableException(String message){
        RetryableExceptionInfo info = new RetryableExceptionInfo();
        info.sz = sz;
        info.msg = message!=null && message.length()>200 ? message.substring(0,200) : message;
        throw new EventBus.RetryableException(JSON.serialize(info));
    }

    /**
     * Retrieves the last scope size from the last error if the previous run
     * threw a retryable exception
     * @param lastError The last error to parse for the scope size
     * @return The scope size of the last attempt or null if no previous error or incorrect format
     */
    static Integer getLastScopeSize(String lastError){
        if(lastError!=null){
            try{
                return ((RetryableExceptionInfo)JSON.deserialize(lastError, RetryableExceptionInfo.class)).sz;
            }
            catch(Exception e){}
        }
        return null;
    }

    /**
     * Retrieves the last processed replay id
     * @return The last processed replay id
     */
    public String getLastReplayId(){
        return lastProcessedReplayId;
    }

    /**
     * Structure for the retry info thrown as message wen throwing retryable exceptions
     */
    class RetryableExceptionInfo{
        /**
         * The size of the scope operated upon
         */
        Integer sz;
        /**
         * The error message
         */
        String msg;
    }

    /**
     * Base class for all Event Notifcation Service Events
     */
    abstract class EnsEvent{
        /**
         * The untyped deserialized form of all info for the event
         */
        Map<String,Object> infoMap;
        /**
         * The unique id of the message to which this event relates, set only for transactional events
         */
        String messageKey;
        /**
         * The alternative unique id of the message to which this event relates, set for both transactional and engagement event
         */
        String compositeId;
        /**
         * Creates an event instance from a platform event record representing the event notification service event
         * @param evt The event record
         */
        EnsEvent(MCENS_EnsEvent__e evt){
            this.infoMap = (Map<String,Object>)JSON.deserializeUntyped(evt.Info__c);
            this.messageKey = (String)infoMap.get('messageKey');
            this.compositeId = evt.CompositeId__c;
        }

        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        abstract void setStatus(IRR_CommunicationLog__c log);

        abstract String getStatus();
    }

    /**
     * Base class for all transactional send events
     */
    abstract class TransactionalSendEvent extends EnsEvent{
        /**
         * The address of the intended recipient of the message to which this event related
         */
        String to;
        /**
         * The subscriptino kewy of the intended recipient in marketing cloud of the message to which this event relates
         */
        String subscriberKey;
        /**
         * Creates an event instance from a platform event record representing the event notification service event
         * @param evt The event record
         */
        TransactionalSendEvent(MCENS_EnsEvent__e evt){
            super(evt);
            //Remove the UUID since it is not present in the engagement events
            if(this.compositeId!=null && UUID_PREFIX_PATTERN.matcher(this.compositeId).matches())this.compositeId = this.compositeId.substring(37);
            this.to = (String)infoMap.get('to');
            this.subscriberKey = (String)infoMap.get('subscriberKey');
        }
    }

    /**
     * Event representing a successful email
     */
    class EmailSent extends TransactionalSendEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        EmailSent(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Sent';
        }

        override String getStatus() {
            return 'Sent';
        }
    }

    /**
     * Event representing a unsuccessful email
     */
    class EmailNotSent extends TransactionalSendEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        EmailNotSent(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Error';
            log.IRR_StatusCode__c = Decimal.valueOf((String)this.infoMap.get('statusCode'));
            log.IRR_ErrorMessage__c = ((String)this.infoMap.get('statusMessage')).abbreviate(2000);
            log.IRR_ErrorReason__c = ((String)this.infoMap.get('reason')).abbreviate(2000);
        }

        override String getStatus() {
            return 'Error';
        }
    }
    /**
     * Event representing a bounced email
     */
    class EmailBounced extends TransactionalSendEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        EmailBounced(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Bounced';
            log.IRR_StatusCode__c = -1;
            log.IRR_ErrorMessage__c = (((String)this.infoMap.get('bounceCode')) +': '+ ((String)this.infoMap.get('bounceMessage'))).abbreviate(2000);
            log.IRR_ErrorReason__c = ((String)this.infoMap.get('smtpReason')).abbreviate(2000);
        }

        override String getStatus() {
            return 'Bounced';
        }
    }

    /**
     * Base class for all engagement events
     */
    abstract class EngagementEvent extends EnsEvent{
        /**
         * Creates an event instance from a platform event record representing the event notification service event
         * @param evt The event record
         */
        EngagementEvent(MCENS_EnsEvent__e evt){
            super(evt);
        }
    }

    /**
     * Event representing when an email was opened
     */
    class EmailOpen extends EngagementEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        EmailOpen(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Opened';
        }

        override String getStatus() {
            return 'Opened';
        }
    }

    /**
     * Event representing a successful sms
     */
    class SmsSent extends TransactionalSendEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        SmsSent(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Sent';
        }

        override String getStatus() {
            return 'Sent';
        }
    }

    /**
     * Event representing a unsuccessful sms
     */
    class SmsNotSent extends TransactionalSendEvent {
        /**
         * Creates instance of the event type
         * @param evt The event record
         */
        SmsNotSent(MCENS_EnsEvent__e evt){super(evt);}
        /**
         * Sets the status of the log record according to the event
         * @param log The communication log record of which to set the 
         */
        override void setStatus(IRR_CommunicationLog__c log){
            log.IRR_Status__c = 'Error';
            log.IRR_StatusCode__c = Decimal.valueOf((String)this.infoMap.get('statusCode'));
            log.IRR_ErrorReason__c = ((String)this.infoMap.get('reason')).abbreviate(2000);
        }

        override String getStatus() {
            return 'Error';
        }
    }
}