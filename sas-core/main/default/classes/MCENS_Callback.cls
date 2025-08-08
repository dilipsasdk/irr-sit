/**
 * Class used to supply a REST resource with the purpose to act 
 * as the callback for Marketing Cloud Event Notification Service
 * @author Peter Södergren
 */
@RestResource(urlMapping='/mc-ens/callback/*')
global without sharing class MCENS_Callback {
    /**
     * The main callback method used to receive the callbacks and
     * process the events in the callback.
     */
    @HttpPost
    global static void doPost(){
        if(System.getApplicationReadWriteMode()==System.ApplicationReadWriteMode.READ_ONLY)setResponse(503,'Service Unavailable');
        else {
            try{
                String uuid = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')+1);
                if(uuid.indexOf('?')!=-1)uuid = uuid.substring(0,uuid.indexOf('?'));
                if(!String.isBlank(uuid)){
                    Object reqObj = JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                    if(reqObj instanceof Map<String,Object>){
                        Map<String,Object> req = (Map<String,Object>)reqObj;
                        if(req.containsKey('callbackId') && req.containsKey('verificationKey')){
                            MCENS_SubscriptionService.registerVerification((String)req.get('callbackId'), (String)req.get('verificationKey'), uuid);
                            setResponse(200,'OK');
                        }
                        else setResponse(400,'Bad Request, Missing parameters (callbackId,verificationKey)');
                    }
                    else if(reqObj instanceof List<Object>){
                        String signature = RestContext.request.headers.get('X-SFMC-ENS-Signature');
                        if(String.isNotBlank(signature)){
                            MCENS_Callback__c cb = [SELECT Id,CallbackId__c,SignatureKey__c FROM MCENS_Callback__c WHERE UUID__c=:uuid];
                            if(Crypto.verifyHmac('hmacSHA256', RestContext.request.requestBody, EncodingUtil.base64Decode(cb.SignatureKey__c), EncodingUtil.base64Decode(signature))){
                                List<Database.SaveResult> srList = EventBus.publish(createEnsEvents((List<Object>)reqObj));
                                String errors = '';
                                for(Integer i=0,sz=srList.size();i<sz;i++){
                                    if(!srList[i].isSuccess()){
                                        Database.SaveResult sr = srList[i];
                                        errors += (sr.errors.size()>0 ? String.join(sr.errors,',') : 'Unkown error') + '\n';
                                    }
                                }
                                if(String.isBlank(errors)){
                                    setResponse(200,'OK');
                                }
                                else {
                                    setResponse(500,'Internal Server Error');
                                    C_Log.log(C_Log.Severity.Error, 500+' '+errors, null, 'MCENS', C_Log.generateLogHttpData(RestContext.request));
                                }
                            }
                            else setResponse(400,'Bad Request, Signature verification failed');
                        }
                        else setResponse(400,'Bad Request, No signature');
                    }
                    else setResponse(400,'Bad Request, Unrecognized message format');
                }
                else setResponse(400,'Bad Request, No matching UUID');
            }
            catch(Exception e){
                setResponse(500,'Internal Server Error');
                C_Log.log(C_Log.Severity.Error, 500+' '+e.getMessage(), e.getStackTraceString(), 'MCENS', C_Log.generateLogHttpData(RestContext.request));
            }
        }
    }

    /**
     * Sets the response to the REST request
     * @param statusCode The status code to set as response
     * @param responseBody The text body to set for the message
     */
    static void setResponse(Integer statusCode,String responseBody){
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(responseBody);
        if(statusCode==400)C_Log.log(C_Log.Severity.Error, statusCode+' '+responseBody, null, 'MCENS', C_Log.generateLogHttpData(RestContext.request));
    }
    /**
     * Creates the ENS Events as platform events from the unstructured JSON deserialization of a message
     * @param evtList The unstructured JSON deserialization of the list of events
     */
    static MCENS_EnsEvent__e[] createEnsEvents(List<Object> evtList){
        Integer sz = evtList.size();
        MCENS_EnsEvent__e[] ensEvtList = new MCENS_EnsEvent__e[sz];
        for(Integer i=0;i<sz;i++){
            Map<String,Object> evt = (Map<String,Object>)evtList[i];
            MCENS_EnsEvent__e ensEvt = new MCENS_EnsEvent__e();
            ensEvt.Type__c = (String)evt.get('eventCategoryType');
            ensEvt.Timestamp__c = (Long)evt.get('timestampUTC');
            ensEvt.CompositeId__c = (String)evt.get('compositeId');
            ensEvt.DefinitionKey__c = (String)evt.get('definitionKey');
            ensEvt.MId__c = (Integer)evt.get('mid');
            ensEvt.EId__c = (Integer)evt.get('eid');
            ensEvt.Info__c = JSON.serialize(evt.get('info'));
            ensEvtList[i] = ensEvt;
        }
        return ensEvtList;
    }

    

}
