
/**
* @author Gaurav singh, Coforge
* @date 2024
*
* @description This class is used to short pass right url and store in custom setting.
*/

global without sharing class IRR_BCH_ShortPassRightUrl implements Database.Batchable<sObject> , Database.AllowsCallouts , Schedulable {
   
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('Select Id,IRR_EU_Pass_Right_Short_URL__c, IRR_EU_Pass_Right_URL__c from IRR_Shorten_Url__c');
       }
         
         global void execute (
         Database.BatchableContext bc,
         IRR_Shorten_Url__c[] sObjScope
       ) {
       
        for ( IRR_Shorten_Url__c message : sObjScope ) {
            //calling shorten url api
            IRR_MOD_ShortenURL shrtenUrlRes = new IRR_MOD_ShortenURL();
            shrtenUrlRes = IRR_SVC_ShortenURLService.generateShortenUrl(new List<String> {message.IRR_EU_Pass_Right_URL__c });
           
                if(shrtenUrlRes != null && shrtenUrlRes.shortenedUrls != null){
                    for(IRR_MOD_ShortenURL.ShortURL shortURL : shrtenUrlRes.shortenedUrls){
                        message.IRR_EU_Pass_Right_Short_URL__c = shortURL.shortenedUrl;
                        }
                }
                else{
                    message.IRR_EU_Pass_Right_Short_URL__c = System.Label.EU_Passenger_Right;
                }
                  
             
        }

        update sObjScope;
    }
    
         
         global void finish(Database.Batchablecontext BC){
             
         }
         
        global void execute(SchedulableContext context) {
         if(!Test.isRunningTest())
         Database.executeBatch(new IRR_BCH_ShortPassRightUrl(),1);
       }
}