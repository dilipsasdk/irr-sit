/**
 * Service class used to facilliatate subscription interactions 
 * with Marketing Cloud Event Notification Service
 * @author Peter Södergren
 */
public with sharing class MCENS_SubscriptionService {
    /**
     * The base url for the marketing cloud endpoint
     */
    static final String BASE_URL = 'callout:SAS_MC_API';
    /**
     * Exception thrown when issues occur within the subscription service
     */
    public class SubscriptionServiceException extends Exception{
        /**
         * Creates a subscription service exception from an http response
         * @param resp The http response from which to create the subscription service exceptions
         */
        SubscriptionServiceException(HttpResponse res){
            this(res.getStatusCode()+' - '+res.getStatus()+' - '+res.getBody());
        }
    }
    
    /**
     * Initiates the registration process for a callback with the supplied properties
     * @param callbackName The name of the callback to register
     * @param callbackUrl The url of the endpoint which should process the events
     * @param batchSize The number of events to process per call to the endpoint
     */
    static CreateCallbackResponse createCallback(String callbackName, String callbackUrl, Integer batchSize){
        CreateCallbackRequest r = new CreateCallbackRequest();
        r.callbackName = callbackName;
        r.url = callbackUrl;
        r.maxBatchSize = batchSize;
        HttpResponse res = doPost('/platform/v1/ens-callbacks',JSON.serialize(new CreateCallbackRequest[]{r}));
        if(res.getStatusCode()!=201)throw new SubscriptionServiceException(res);
        return ((List<CreateCallbackResponse>)JSON.deserialize(res.getBody(), List<CreateCallbackResponse>.class))[0];
    }

    /**
     * Verifies the callback using the ENS supplied verification key
     * @param callbackId The id of the callback to verify
     * @param verificationKey The key used to verify the callback
     */
    static void verifyCallback(String callbackId, String verificationKey){
        VerifyCallbackRequest r = new VerifyCallbackRequest();
        r.callbackId = callbackId;
        r.verificationKey = verificationKey;
        HttpResponse res = doPost('/platform/v1/ens-verify',JSON.serialize(r));
        if(res.getStatusCode()!=200)throw new SubscriptionServiceException(res);
    }

    /**
     * Registers the verification of the callback using the provided verification key
     * This verifies the callback to marketing cloud and creates a callback record in Salesforce
     * @param callbackId The id of the callback to verify
     * @param verificationKey The key used to verify the callback
     * @param uuid The uuid of the verified callback
     */
    public static void registerVerification(String callbackId, String verificationKey, String uuid){
        verifyCallback(callbackId, verificationKey);
        insert new MCENS_Callback__c(CallbackId__c=callbackId, UUID__c=uuid);
    }

    /**
     * Registers a callback with the supplied properties against the Marketing Cloud Event Notification Service
     * using the supplied parameters.
     * @param callbackName The name of the callback to register
     * @param callbackUrl The url of the endpoint which should process the events
     * @param batchSize The number of events to process per call to the endpoint
     * @return The Salesforce record representing the callback
     */
    @AuraEnabled public static MCENS_Callback__c registerCallback(String callbackName, String callbackUrl, Integer batchSize){
        String uuid = C_Util.generateUUID();
        callbackUrl+=(callbackUrl.endsWith('/') ? '' : '/')+uuid;
        CreateCallbackResponse ccr = createCallback(callbackName,callbackUrl,batchSize);
        MCENS_Callback__c cb = new MCENS_Callback__c();
        cb.Name = ccr.callbackName;
        cb.CallbackId__c = ccr.callbackId;
        cb.CallbackUrl__c = ccr.url;
        cb.BatchSize__c = ccr.maxBatchSize;
        cb.SignatureKey__c = ccr.signatureKey;
        cb.UUID__c = uuid;
        upsert cb CallbackId__c;
        return cb;
    }
    /**
     * Deletes the callback with the provided callback id
     * @param callbackId The id of the callback to delete
     */
    public static void deleteCallback(String callbackId){
        HttpResponse res = doDelete('/platform/v1/ens-callbacks/'+callbackId);
        if(res.getStatusCode()!=200)throw new SubscriptionServiceException(res);
    }

    /**
     * Deletes the local callback record including the corresponding marketing cloud ens callback
     * @param callbackRecordId The id of the local callback record to delete
     */
    @AuraEnabled public static void deleteCallbackRecord(Id callbackRecordId){
        MCENS_Callback__c cb = [SELECT Id,CallbackId__c FROM MCENS_Callback__c WHERE Id=:callbackRecordId];
        deleteCallback(cb.CallbackId__c);
        delete cb;
    }

    /**
     * Retrieves all subscriptions registered for the provided callback id
     * @param callbackId The marketing cloud callback id for which to fetch the subscriptions
     * @return All subscriptions for the referenced callback id
     */
    static Subscription[] getSubscriptionsByCallback(String callbackId){
        HttpResponse res = doGet('/platform/v1/ens-subscriptions-by-cb/'+callbackId);
        if(res.getStatusCode()!=200)throw new SubscriptionServiceException(res);
        return (Subscription[])JSON.deserialize(res.getBody(), List<Subscription>.class);
    }

    /**
     * Retrieves the subscriptions for the provided callback id
     * @param callbackRecordId The callback record if for which to fetch the subscriptions
     * @return All subscriptions for the specified callback
     */
    @AuraEnabled public static Subscription[] getSubscriptionsForRecord(Id callbackRecordId){
        MCENS_Callback__c rec = [SELECT Id,CallbackId__c FROM MCENS_Callback__c WHERE Id=:callbackRecordId];
        return getSubscriptionsByCallback(rec.CallbackId__c);
    }

    /**
     * Creates a subscription in Marketing Cloud
     * @param callbackId The id of the callback in Marketing Cloud to which the subscription should be connected
     * @param subscriptionName The name of the subscription
     * @param eventCategoryTypes The list of event categories which should be subscribed to
     * @param filters The list of filters to apply to the events
     * @return The data of the created subscription
     */
    static Subscription createSubscription(String callbackId, String subscriptionName,List<String> eventCategoryTypes, List<String> filters){
        CreateSubscriptionRequest r = new CreateSubscriptionRequest();
        r.callbackId = callbackId;
        r.subscriptionName = subscriptionName;
        r.eventCategoryTypes = eventCategoryTypes;
        r.filters = filters;
        HttpResponse res = doPost('/platform/v1/ens-subscriptions',JSON.serialize(new CreateSubscriptionRequest[]{r}));
        if(res.getStatusCode()!=201)throw new SubscriptionServiceException(res);
        return ((List<Subscription>)JSON.deserialize(res.getBody(), List<Subscription>.class))[0];
    }

    /**
     * Creates a subscription in Marketing Cloud
     * @param callbackRecordId The id of the Salesforce callback record id to which to connect the subscription
     * @param subscriptionName The name of the subscription
     * @param eventCategoryTypes The list of event categories which should be subscribed to
     * @param filters The list of filters to apply to the events
     * @return The data of the created subscription
     */
    @AuraEnabled public static Subscription createSubscriptionForRecord(Id callbackRecordId, String subscriptionName, List<String> eventCategoryTypes, List<String> filters){
        MCENS_Callback__c rec = [SELECT Id,CallbackId__c FROM MCENS_Callback__c WHERE Id=:callbackRecordId];
        return createSubscription(rec.CallbackId__c, subscriptionName, eventCategoryTypes, filters);
    }

    /**
     * Deletes the subscription of the specified subscription id
     * @param subscriptionId The subscription id to delete
     */
    @AuraEnabled public static void deleteSubscription(String subscriptionId){
        HttpResponse res = doDelete('/platform/v1/ens-subscriptions/'+subscriptionId);
        if(res.getStatusCode()!=200)throw new SubscriptionServiceException(res);
    }

    /**
     * Class used to represent a subscription
     */
    public class Subscription{
        /**
         * The marketing cloud id of the callback to which the subscription is connected
         */
        @AuraEnabled public String callbackId;
        /**
         * The name of the callback to which the subscription is connected
         */
        @AuraEnabled public String callbackName;
        /**
         * The url of the callback to which the subscription is connected
         */
        @AuraEnabled public String url;
        /**
         * The maximum size of event batches of the callback to which the subscription is connected
         */
        @AuraEnabled public Integer maxBatchSize;
        /**
         * The id of the subscription in Marketing Cloud
         */
        @AuraEnabled public String subscriptionId;
        /**
         * The name of the subcription
         */
        @AuraEnabled public String subscriptionName;
        /**
         * The event cateogry types in the subscription
         */
        @AuraEnabled public List<String> eventCategoryTypes;
        /**
         * The filters applied to the subcription
         */
        @AuraEnabled public List<String> filters;
        /**
         * The status of the subscription
         */
        @AuraEnabled public String status;
        /**
         * Additional information related to the status of the subscriptions
         */
        @AuraEnabled public String statusReason;
    }

    /**
     * Class containing the properties for requests to create a subscription
     */
    class CreateSubscriptionRequest{
        /**
         * The name to give the subscription
         */
        String subscriptionName;
        /**
         * The callback to which to connect the subscription
         */
        String callbackId;
        /**
         * The event categories subscribed to
         */
        String[] eventCategoryTypes;
        /**
         * The filters to apply to the subscribed events
         */
        String[] filters;

    }

    /**
     * Class containing the properties for requests to verify a callback
     */
    class VerifyCallbackRequest{
        /**
         * The id of the callback to verify
         */
        String callbackId;
        /**
         * The key used to verify the callback
         */
        String verificationKey;
    }

    /**
     * Class containing the properties for a request to create a callback
     */
    class CreateCallbackRequest{
        /**
         * The name of the callback to register
         */
        String callbackName;
        /**
         * The url of the endpoint which should process the events
         */
        String url;
        /**
         * The number of events to process per call to the endpoint
         */
        Integer maxBatchSize;
    }
    /**
     * Class containing the response data when requesting to create a callback
     */
    class CreateCallbackResponse{
        /**
         * The name of the created callback
         */
        String callbackName;
        /**
         * The url of the endpoint which should process the events
         */
        String url;
        /**
         * The number of events to process per call to the endpoint
         */
        Integer maxBatchSize;
        /**
         * The id of the callback used when referencing the callback in later requests to marketing cloud
         */
        String callbackId;
        /**
         * The key used to sign notifications delivered to the callback
         */
        String signatureKey;
    }

    /**
     * Sends a post request to the marketing cloud API
     * @param resource The resource in marketing cloud which should be posted to
     * @param body The content to send to marketing cloud
     * @return The HTTP response object returned by calling the service
     */
    static HttpResponse doPost(String resource,String body){
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(BASE_URL+resource);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        return new Http().send(req);
    }

    /**
     * Sends a get request to the marketing cloud API
     * @param resource The resource in marketing cloud which should be fetched
     * @return The HTTP response object returned by calling the service
     */
    static HttpResponse doGet(String resource){
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(BASE_URL+resource);
        req.setHeader('Content-Type', 'application/json');
        return new Http().send(req);
    }

    /**
     * Sends a delete request to the marketing cloud API
     * @param resource The resource in marketing cloud which should be deleted
     * @return The HTTP response object returned by calling the service
     */
    static HttpResponse doDelete(String resource){
        HttpRequest req = new HttpRequest();
        req.setMethod('DELETE');
        req.setEndpoint(BASE_URL+resource);
        req.setHeader('Content-Type', 'application/json');
        return new Http().send(req);
    }
}
