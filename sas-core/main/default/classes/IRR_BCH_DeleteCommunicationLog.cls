/**
 * @author Gaurav Singh
 * @date 2024-06-12
 * @description batch job for delete communication log from salesforce
 */

public with sharing class IRR_BCH_DeleteCommunicationLog implements Database.Batchable<sObject>,Schedulable {
       
    public Database.QueryLocator start(Database.BatchableContext bc) {
    return IRR_SEL_CommunicationLogsSelector.newInstance()
    .getCommunicationLogByDateQueryLocator();
   }
     
   public void execute (
     Database.BatchableContext bc,
     IRR_CommunicationLog__c[] commList
   ) {
     fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
     for(IRR_CommunicationLog__c commLog : commList){
         uow.registerDeleted(commLog);
     } 
     uow.commitWork();
   }
   public void finish(Database.Batchablecontext BC){
         
    }
    public void execute(SchedulableContext ctx) {
     ID batchprocessid = Database.executeBatch(new IRR_BCH_DeleteCommunicationLog() ,1000);
  }

}